import 'package:air_mind/screens/datasource.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({
    super.key,
    required this.threads,
    required this.onSelectThread,
    required this.onDeleteThread,
  });
  final Stream<QuerySnapshot<Map<String, dynamic>>> threads;
  final void Function(String threadId) onSelectThread;
  final void Function(String threadId) onDeleteThread;

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> with TickerProviderStateMixin {
  int? _selectedIndex;
  // Map to track which items are being deleted
  final Map<String, AnimationController> _deleteAnimationControllers = {};

  @override
  void dispose() {
    // Dispose all animation controllers
    _deleteAnimationControllers
        .forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Delete with animation
  void _animatedDeleteThread(BuildContext context, String threadId, int index) {
    // Create an animation controller for this specific deletion
    final animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Store the controller
    _deleteAnimationControllers[threadId] = animController;

    // Trigger rebuild to show animation
    setState(() {});

    // Start animation
    animController.forward().then((_) {
      // When animation completes, call the actual delete function
      widget.onDeleteThread(threadId);

      // Remove controller after use
      animController.dispose();
      _deleteAnimationControllers.remove(threadId);

      // Clear selection
      setState(() {
        _selectedIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero, // Remove padding to have more control
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/AirMind.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'AirMind',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your Personal Thinking Space',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),
          // List of Threads goes here
          Expanded(
            child: StreamBuilder(
                stream: widget.threads,
                builder: (context, threadSnapshots) {
                  if (threadSnapshots.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!threadSnapshots.hasData ||
                      threadSnapshots.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No messages found.'),
                    );
                  }

                  if (threadSnapshots.hasError) {
                    return Center(
                      child: Text('Something went wrong...'),
                    );
                  }

                  final loadedThreads = threadSnapshots.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: loadedThreads.length,
                    itemBuilder: (ctx, index) {
                      final threadId = loadedThreads[index].id;
                      final isDeleting =
                          _deleteAnimationControllers.containsKey(threadId);

                      // Apply slide animation only when deleting
                      final slideAnimation = isDeleting
                          ? _deleteAnimationControllers[threadId]!
                          : null;

                      Widget listTile = ListTile(
                        onTap: () {
                          if (!isDeleting) {
                            widget.onSelectThread(threadId);
                          }
                        },
                        onLongPress: () {
                          if (!isDeleting) {
                            setState(() {
                              _selectedIndex =
                                  _selectedIndex == index ? null : index;
                            });
                          }
                        },
                        title: Text(
                          loadedThreads[index].data()['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _selectedIndex == index
                            ? IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () {
                                  _animatedDeleteThread(
                                      context, threadId, index);
                                },
                              )
                            : null,
                        selected: _selectedIndex == index,
                      );

                      // Wrap with slide transition only if deleting
                      if (isDeleting) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset.zero,
                            end: const Offset(-1.0, 0.0),
                          ).animate(slideAnimation!),
                          child: listTile,
                        );
                      }

                      return listTile;
                    },
                  );
                }),
          ),
          // Footer section
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
            ),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => DatasourceScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.storage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Datasource',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
