import 'package:air_mind/widgets/connection_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mdb_dart/mdb_dart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

final client = Client(dotenv.env['MINDS_API_KEY']!);

class DatasourceScreen extends StatefulWidget {
  const DatasourceScreen({super.key});

  @override
  State<DatasourceScreen> createState() => _DatasourceScreenState();
}

class _DatasourceScreenState extends State<DatasourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Form data controllers
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _databaseController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _sslModeController;
  late TextEditingController _descriptionController;
  late TextEditingController _schemaController;

  // Form data value
  String _host = 'localhost';
  String _port = '5432';
  String _database = '';
  String _username = '';
  String _password = '';
  String _sslMode = 'prefer';
  String _description = '';
  String _schema = 'public';

  bool _isLoading = false;
  bool _isFetchingDsConfig = false;
  String? _connectionStatus;
  bool _obscurePassword = true;

  Future<void> _loadConnection(dataSourceName) async {
    setState(() {
      _isFetchingDsConfig = true;
    });
    try {
      final dataSource = await client.datasources.get(dataSourceName);

      // Update values
      _host = dataSource.connectionData['host'] ?? 'localhost';
      _port = dataSource.connectionData['port'] ?? '5432';
      _database = dataSource.connectionData['database'] ?? '';
      _username = dataSource.connectionData['user'] ?? '';
      _password = dataSource.connectionData['password'] ?? '';
      _sslMode = dataSource.connectionData['sslmode'] ?? 'prefer';
      _description = dataSource.description;
      _schema = dataSource.connectionData['schema'] ?? 'public';

      // Update controllers
      setState(() {
        _hostController.text = _host;
        _portController.text = _port;
        _databaseController.text = _database;
        _usernameController.text = _username;
        _passwordController.text = _password;
        _sslModeController.text = _sslMode;
        _descriptionController.text = _description;
        _schemaController.text = _schema;
      });
    } catch (e) {
      // Connection not found
    } finally {
      setState(() {
        _isFetchingDsConfig = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: _host);
    _portController = TextEditingController(text: _port);
    _databaseController = TextEditingController(text: _database);
    _usernameController = TextEditingController(text: _username);
    _passwordController = TextEditingController(text: _password);
    _sslModeController = TextEditingController(text: _sslMode);
    _descriptionController = TextEditingController(text: _description);
    _schemaController = TextEditingController(text: _schema);

    _loadConnection(userId);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _sslModeController.dispose();
    _descriptionController.dispose();
    _schemaController.dispose();
    super.dispose();
  }

  void _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _connectionStatus = null;
    });

    final dsConfig = DatabaseConfig(
      name: userId,
      engine: 'postgres',
      description: _description,
      connectionData: {
        'user': _username,
        'password': _password,
        'host': _host,
        'port': _port,
        'sslmode': _sslMode,
        'database': _database,
        'schema': _schema,
      },
    );

    try {
      await client.datasources.create(
        dsConfig,
        replace: true,
      );

      setState(() {
        _connectionStatus = 'Connection successful!';
      });
      return;
    } catch (e) {
      if (e.toString().contains('Datasource exists')) {
        try {
          await client.datasources.drop(userId);
          await client.datasources.create(dsConfig, replace: true);
        } catch (e) {
          if (e.toString().contains('Datasource in use')) {
            await client.minds.drop(userId);
            await client.datasources.drop(userId);
            await client.datasources.create(dsConfig, replace: true);
            setState(() {
              _connectionStatus = 'Connection successful!';
            });
            return;
          }

          setState(() {
            _connectionStatus = 'Connection failed: ${e.toString()}';
          });
        }
      }
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datasource Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ConnectionInfo(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PostgreSQL Database',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Host field
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'Host',
                        hintText: 'e.g., localhost or 192.168.1.1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter host address';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _host = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Port field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: 'Default: 5432',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter port number';
                              }
                              final port = int.tryParse(value);
                              if (port == null || port <= 0 || port > 65535) {
                                return 'Enter a valid port (1-65535)';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _port = value ?? '';
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        // SSL Mode field
                        Expanded(
                          child: TextFormField(
                            controller: _sslModeController,
                            decoration: const InputDecoration(
                              labelText: 'SSL Mode',
                              hintText: 'Default: prefer',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_clock),
                            ),
                            onSaved: (value) {
                              _sslMode = value ?? 'prefer';
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Database name field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _databaseController,
                            decoration: const InputDecoration(
                              labelText: 'Database Name',
                              hintText: 'e.g., my_database',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.storage),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter database name';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _database = value ?? '';
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _schemaController,
                            decoration: const InputDecoration(
                              labelText: 'Schema',
                              hintText: 'Default: public',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.table_chart),
                            ),
                            onSaved: (value) {
                              _schema = value ?? 'public';
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g., postgres',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _username = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Work Database',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value ?? '';
                      },
                    ),
                    const SizedBox(height: 24),

                    // Connection status indicator
                    if (_connectionStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: _connectionStatus!.contains('successful')
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _connectionStatus!,
                            style: TextStyle(
                              color: _connectionStatus!.contains('successful')
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ),

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveConnection,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                            label:
                                Text(_isLoading ? 'Connecting...' : 'Connect'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: InkWell(
                          onTap: () async {
                            final Uri url = Uri.parse('https://airbyte.com/');
                            if (!await launchUrl(url)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Could not open Airbyte website'),
                                ),
                              );
                            }
                          },
                          child: Text(
                            "Don't have data in PostgreSQL? Airbyte can help transfer your data!",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isFetchingDsConfig)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
