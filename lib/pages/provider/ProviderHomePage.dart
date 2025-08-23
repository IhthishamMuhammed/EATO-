// File: lib/pages/provider/ProviderHomePage.dart
// Modified version without bottom navigation bar

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/pages/provider/AddFoodPage.dart';
import 'package:eato/pages/provider/EditFoodPage.dart';
import 'package:eato/Model/Food&Store.dart';
import 'dart:async';

class ProviderHomePage extends StatefulWidget {
  final CustomUser currentUser;

  const ProviderHomePage({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _ProviderHomePageState createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage>
    with SingleTickerProviderStateMixin {
  String _selectedMealTime = 'Breakfast';
  final List<String> _mealTimes = ['Breakfast', 'Lunch', 'Dinner'];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealTimes.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    _loadStoreAndFoods();

    // Set up search controller listener
    _searchController.addListener(() {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedMealTime = _mealTimes[_tabController.index];
      });

      // Apply filter for meal time
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      foodProvider.setFilterMealTime(_selectedMealTime);
    }
  }

  Future<void> _loadStoreAndFoods() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    // Only show loading if no data is cached
    if (storeProvider.userStore == null || foodProvider.foods.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (storeProvider.userStore == null) {
        await storeProvider.fetchUserStore(widget.currentUser);
      }

      if (storeProvider.userStore != null && foodProvider.foods.isEmpty) {
        await foodProvider.fetchFoods(storeProvider.userStore!.id);
        foodProvider.setFilterMealTime(_selectedMealTime);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadStoreAndFoods();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _navigateToAddFood() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final storeId = storeProvider.userStore?.id ?? '';

    if (storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up your store first'),
          backgroundColor: EatoTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodPage(
          storeId: storeId,
        ),
      ),
    ).then((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  void _navigateToEditFood(Food food) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final storeId = storeProvider.userStore?.id ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoodPage(
          storeId: storeId,
          food: food,
        ),
      ),
    ).then((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  Future<void> _confirmDeleteFood(String foodId, String foodName) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final storeId = storeProvider.userStore?.id ?? '';

    if (storeId.isEmpty) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Delete Food'),
          content: Text(
            'Are you sure you want to delete "$foodName"?\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: EatoTheme.textButtonStyle,
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  setState(() {
                    _isLoading = true;
                  });

                  await Provider.of<FoodProvider>(context, listen: false)
                      .deleteFood(storeId, foodId);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$foodName deleted successfully'),
                        backgroundColor: EatoTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete food: $e'),
                        backgroundColor: EatoTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: EatoTheme.inputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon:
                      Icon(Icons.search, color: EatoTheme.textSecondaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = false;
                        _searchController.clear();
                      });
                      foodProvider.setSearchQuery('');
                    },
                  ),
                ),
                style: EatoTheme.bodyMedium,
              )
            : Text(
                'My Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: EatoTheme.textPrimaryColor,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: _showSearchBar ? false : true,
        leadingWidth: _showSearchBar ? 0 : null,
        leading: _showSearchBar
            ? null
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: EatoTheme.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        actions: [
          if (!_showSearchBar)
            IconButton(
              icon: Icon(Icons.search, color: EatoTheme.textPrimaryColor),
              onPressed: () {
                setState(() {
                  _showSearchBar = true;
                });
              },
            ),
          if (!_showSearchBar)
            IconButton(
              icon: Icon(Icons.filter_list, color: EatoTheme.textPrimaryColor),
              onPressed: () {
                // Show filter options
                _showFilterBottomSheet();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: EatoTheme.primaryColor,
          unselectedLabelColor: EatoTheme.textSecondaryColor,
          indicatorColor: EatoTheme.primaryColor,
          tabs: _mealTimes.map((mealTime) {
            return Tab(text: mealTime);
          }).toList(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: EatoTheme.primaryColor))
          : storeProvider.userStore == null
              ? _buildNoStoreView()
              : _buildFoodListView(foodProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFood,
        backgroundColor: EatoTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoStoreView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: EatoTheme.textLightColor,
          ),
          SizedBox(height: 16),
          Text(
            'No Food Items Found',
            style: EatoTheme.headingMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Add your first food item to start your menu',
            style: EatoTheme.bodyMedium
                .copyWith(color: EatoTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to AddFoodPage
              final storeProvider =
                  Provider.of<StoreProvider>(context, listen: false);
              final storeId = storeProvider.userStore?.id ?? '';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFoodPage(
                    storeId: storeId,
                  ),
                ),
              ).then((_) {
                // Refresh data when returning
                _refreshIndicatorKey.currentState?.show();
              });
            },
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add Food'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodListView(FoodProvider foodProvider) {
    final filteredFoods = foodProvider.foods;

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      color: EatoTheme.primaryColor,
      child: Column(
        children: [
          // Add new food button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _navigateToAddFood,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.0),
                decoration: BoxDecoration(
                  color: EatoTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: EatoTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Food',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Food list
          Expanded(
            child: filteredFoods.isEmpty
                ? _buildEmptyFoodList()
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 80),
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      return _buildFoodCard(food);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFoodList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No food items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start by adding your first food item.',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: EatoTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image with overlay actions
            Stack(
              children: [
                // Food image or placeholder
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: food.imageUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        )
                      : Image.network(
                          food.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: EatoTheme.primaryColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                ),

                // Meal time and food type tags
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EatoTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          food.time,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      if (food.type.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: food.type.toLowerCase().contains('veg')
                                ? EatoTheme.successColor
                                : EatoTheme.warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            food.type,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons (edit, delete)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: IconButton(
                          icon: Icon(Icons.edit,
                              size: 16, color: EatoTheme.primaryColor),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => _navigateToEditFood(food),
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: IconButton(
                          icon: Icon(Icons.delete,
                              size: 16, color: EatoTheme.errorColor),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () =>
                              _confirmDeleteFood(food.id, food.name),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Food details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rs.${food.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: EatoTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  if (food.category.isNotEmpty)
                    Text(
                      food.category,
                      style: TextStyle(
                        color: EatoTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Foods',
                        style: EatoTheme.headingMedium.copyWith(fontSize: 20),
                      ),
                      TextButton(
                        onPressed: () {
                          foodProvider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text('Reset'),
                        style: EatoTheme.textButtonStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Food Type',
                    style: EatoTheme.labelLarge,
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Vegetarian',
                      'Non-Vegetarian',
                      'Vegan',
                      'Dessert',
                    ].map((type) {
                      bool isSelected = foodProvider.getFilterType() == type;
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            foodProvider.setFilterType(type);
                          } else {
                            foodProvider.setFilterType('');
                          }
                          setState(() {});
                        },
                        selectedColor: EatoTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: EatoTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? EatoTheme.primaryColor
                              : EatoTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Food Category',
                    style: EatoTheme.labelLarge,
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Rice and Curry',
                      'String Hoppers',
                      'Roti',
                      'Egg Roti',
                      'Short Eats',
                      'Hoppers',
                    ].map((category) {
                      bool isSelected =
                          foodProvider.getFilterCategory() == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            foodProvider.setFilterCategory(category);
                          } else {
                            foodProvider.setFilterCategory('');
                          }
                          setState(() {});
                        },
                        selectedColor: EatoTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: EatoTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? EatoTheme.primaryColor
                              : EatoTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Apply Filters'),
                      style: EatoTheme.primaryButtonStyle,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
