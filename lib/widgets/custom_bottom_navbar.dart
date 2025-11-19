import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:audoria/utils/backend_services/firebase_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 1; // Default to home icon

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update index based on current route
    final route = ModalRoute.of(context);
    if (route != null) {
      final routeName = route.settings.name;
      if (routeName == 'setting_child' || routeName == 'setting_parent') {
        _currentIndex = 2; // Settings icon
      } else if (routeName == 'child_home' || routeName == 'parent_home') {
        _currentIndex = 1; // Home icon
      }
    }
  }

  Future<void> _handleHomeTap(BuildContext context) async {
    try {
      // Check if already on home screen
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == 'child_home' || currentRoute == 'parent_home') {
        // Already on home screen, just update the index
        setState(() {
          _currentIndex = 1;
        });
        return;
      }

      final userType = await getUserType();

      if (userType == 'child') {
        // Navigate to child home screen
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            'child_home',
            (route) => false,
          ).then((_) {
            // Update index after navigation completes
            if (mounted) {
              setState(() {
                _currentIndex = 1;
              });
            }
          });
        }
      } else if (userType == 'parent') {
        // Navigate to parent home screen
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            'parent_home',
            (route) => false,
          ).then((_) {
            // Update index after navigation completes
            if (mounted) {
              setState(() {
                _currentIndex = 1;
              });
            }
          });
        }
      } else {
        // If we're on child settings, navigate to child home
        if (currentRoute == 'setting_child') {
          // We're on child settings, navigate to child home
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              'child_home',
              (route) => false,
            ).then((_) {
              if (mounted) {
                setState(() {
                  _currentIndex = 1;
                });
              }
            });
            return;
          }
        } else if (currentRoute == 'setting_parent') {
          // We're on parent settings, navigate to parent home
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              'parent_home',
              (route) => false,
            ).then((_) {
              if (mounted) {
                setState(() {
                  _currentIndex = 1;
                });
              }
            });
            return;
          }
        } else {
          // Fallback: try child home
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              'child_home',
              (route) => false,
            ).then((_) {
              if (mounted) {
                setState(() {
                  _currentIndex = 1;
                });
              }
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error navigating to home: $e')));
      }
    }
  }

  Future<void> _handleSettingsTap(BuildContext context) async {
    try {
      // Check if already on settings screen
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == 'setting_child' || currentRoute == 'setting_parent') {
        // Already on settings screen, just update the index
        setState(() {
          _currentIndex = 2;
        });
        return;
      }

      print('Settings tapped - checking user type...');
      final userType = await getUserType();
      print('User type determined: $userType');

      if (userType == 'child') {
        // Navigate to child settings screen
        print('Fetching child data...');
        final childData = await getChildDataForSettings();
        print('Child data fetched: $childData');

        if (context.mounted) {
          print('Navigating to setting_child...');
          Navigator.pushNamed(
            context,
            'setting_child',
            arguments: {'childData': childData},
          ).then((_) {
            // Update index after navigation completes
            if (mounted) {
              setState(() {
                _currentIndex = 2;
              });
            }
          });
          print('Navigation completed');
        } else {
          print('Context not mounted');
        }
      } else if (userType == 'parent') {
        // Navigate to parent settings screen
        final user = FirebaseAuth.instance.currentUser;
        final userData = await getCurrentUserData();
        final childrenData = await getParentChildrenForSettings();

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            'setting_parent',
            arguments: {
              'childrenData': childrenData,
              'parentName': userData?['username']?.toString() ?? 'Parent',
              'parentEmail': user?.email ?? '',
            },
          ).then((_) {
            // Update index after navigation completes
            if (mounted) {
              setState(() {
                _currentIndex = 2;
              });
            }
          });
        }
      } else {
        // Unknown user type - try to navigate based on current screen context
        print('Unknown user type, attempting fallback navigation...');
        print('Current route: $currentRoute');

        // Determine based on current route
        if (currentRoute == 'child_home') {
          // We're on child home, navigate to child settings
          try {
            print('On child home, navigating to child settings...');
            final childData = await getChildDataForSettings();
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                'setting_child',
                arguments: {'childData': childData},
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _currentIndex = 2;
                  });
                }
              });
              return;
            }
          } catch (e) {
            print('Failed to navigate to child settings: $e');
          }
        } else if (currentRoute == 'parent_home') {
          // We're on parent home, navigate to parent settings
          try {
            print('On parent home, navigating to parent settings...');
            final user = FirebaseAuth.instance.currentUser;
            final userData = await getCurrentUserData();
            final childrenData = await getParentChildrenForSettings();
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                'setting_parent',
                arguments: {
                  'childrenData': childrenData,
                  'parentName': userData?['username']?.toString() ?? 'Parent',
                  'parentEmail': user?.email ?? '',
                },
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _currentIndex = 2;
                  });
                }
              });
              return;
            }
          } catch (e) {
            print('Failed to navigate to parent settings: $e');
          }
        } else {
          // Try child settings first (most common case)
          try {
            print('Attempting to navigate to child settings as fallback...');
            final childData = await getChildDataForSettings();
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                'setting_child',
                arguments: {'childData': childData},
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _currentIndex = 2;
                  });
                }
              });
              print('Successfully navigated to child settings');
              return;
            }
          } catch (e) {
            print('Failed to navigate to child settings: $e');
            // Try parent settings as fallback
            try {
              final user = FirebaseAuth.instance.currentUser;
              final userData = await getCurrentUserData();
              final childrenData = await getParentChildrenForSettings();
              if (context.mounted) {
                Navigator.pushNamed(
                  context,
                  'setting_parent',
                  arguments: {
                    'childrenData': childrenData,
                    'parentName': userData?['username']?.toString() ?? 'Parent',
                    'parentEmail': user?.email ?? '',
                  },
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _currentIndex = 2;
                    });
                  }
                });
                return;
              }
            } catch (e2) {
              print('Failed to navigate to parent settings: $e2');
            }
          }
        }

        // If all else fails, show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to navigate to settings. Please try again.',
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error in _handleSettingsTap: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update index based on current route
    final route = ModalRoute.of(context);
    if (route != null) {
      final routeName = route.settings.name;
      if (routeName == 'setting_child' || routeName == 'setting_parent') {
        _currentIndex = 2; // Settings icon
      } else if (routeName == 'child_home' || routeName == 'parent_home') {
        _currentIndex = 1; // Home icon
      }
    }

    return CurvedNavigationBar(
      index: _currentIndex,
      color: Colors.white,
      backgroundColor: const Color(0xFF9BB9FF),
      buttonBackgroundColor: const Color(0xFF9BB9FF),
      items: <Widget>[
        Icon(Icons.person_outline_sharp, size: 30),
        Icon(Icons.home_outlined, size: 30),
        Icon(Icons.settings, size: 30),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        if (index == 1) {
          // Home icon tapped
          _handleHomeTap(context);
        } else if (index == 2) {
          // Settings icon tapped
          _handleSettingsTap(context);
        }
        // Person icon (index 0) - will be implemented later
      },
    );
  }
}
