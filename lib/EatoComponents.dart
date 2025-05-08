import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eato/pages/theme/eato_theme.dart';

/// EatoComponents provides reusable UI elements to maintain consistency across the app.
class EatoComponents {
  // Primary button with gradient background
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double width = double.infinity,
    double height = 50,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading
                ? LinearGradient(
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : EatoTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : [
              BoxShadow(
                color: EatoTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Secondary button with border
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double width = double.infinity,
    double height = 50,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: EatoTheme.primaryColor,
          side: BorderSide(color: EatoTheme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              EatoTheme.primaryColor,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Eato styled form field
  static Widget inputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    IconData? prefixIcon,
    Widget? suffixWidget,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            fontSize: 16,
            color: EatoTheme.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
              prefixIcon,
              color: focusNode?.hasFocus ?? false
                  ? EatoTheme.primaryColor
                  : Colors.grey.shade600,
            )
                : null,
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: prefixIcon == null ? 16 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: EatoTheme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: EatoTheme.errorColor,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: EatoTheme.errorColor,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  // Custom drop-down
  static Widget dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade50,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: value,
              hint: hint != null ? Text(hint) : null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16,
                color: EatoTheme.textPrimaryColor,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: EatoTheme.primaryColor,
              ),
              borderRadius: BorderRadius.circular(16),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Loading overlay
  static Widget loadingOverlay({
    required Widget child,
    required bool isLoading,
    String? loadingText,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: EatoTheme.primaryColor,
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      loadingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Card container for food items
  static Widget foodCard({
    required String name,
    required double price,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? imageUrl,
    String? category,
    String? mealTime,
    bool isAvailable = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and action buttons
            Stack(
              children: [
                // Food Image
                ClipRRect(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.restaurant,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

                // Action buttons
                if (onEdit != null || onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          InkWell(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: EatoTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 8),
                        if (onDelete != null)
                          InkWell(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete,
                                color: EatoTheme.errorColor,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Category badge
                if (category != null && category.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EatoTheme.primaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Not available indicator
                if (!isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Not Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Food info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: EatoTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: EatoTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: EatoTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (mealTime != null && mealTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: EatoTheme.textLightColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mealTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: EatoTheme.textLightColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom section header
  static Widget sectionHeader({
    required String title,
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: EatoTheme.textPrimaryColor,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Custom tab selector
  static Widget tabSelector({
    required List<String> tabs,
    required String selectedTab,
    required Function(String) onTabSelected,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isSelected = tab == selectedTab;
          return GestureDetector(
            onTap: () => onTabSelected(tab),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? EatoTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected
                        ? EatoTheme.primaryColor
                        : EatoTheme.textLightColor,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Empty state for lists
  static Widget emptyState({
    required String message,
    IconData icon = Icons.search_off,
    VoidCallback? onActionPressed,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: EatoTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EatoTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Custom dialog
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: EatoTheme.textPrimaryColor,
            ),
          ),
          content: content,
          actions: actions ??
              [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: EatoTheme.textSecondaryColor,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EatoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
        );
      },
    );
  }

  // Custom toast/snackbar
  static void showToast({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? EatoTheme.errorColor : EatoTheme.successColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: action,
      ),
    );
  }
}