import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  final Color? spinnerColor;
  final Color? backgroundColor;
  final String? loadingText;
  final double spinnerSize;
  final double logoSize;
  final Widget? customLogo;
  final MainAxisAlignment alignment;
  final EdgeInsetsGeometry padding;

  const Loading({
    super.key,
    this.spinnerColor,
    this.backgroundColor,
    this.loadingText = 'Welcome',
    this.spinnerSize = 40.0,
    this.logoSize = 250.0, 
    this.customLogo,
    this.alignment = MainAxisAlignment.center, 
    this.padding = const EdgeInsets.only(top: 40), 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.grey[100],
      body: SingleChildScrollView( 
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: padding,
          child: Center(
            child: Column(
              mainAxisAlignment: alignment,
              children: [
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: customLogo ?? _buildDefaultLogo(context),
                ),
                
                const SizedBox(height: 40), 
                
                SpinKitFadingFour(
                  color: spinnerColor ?? theme.primaryColor,
                  size: spinnerSize,
                ),
                
                if (loadingText != null) ...[
                  const SizedBox(height: 25),
                  Text(
                    loadingText!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      color: (spinnerColor ?? Colors.brown).withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return Image.asset(
      'assets/logo/ccwc_cafe_no_bg.png',
      width: logoSize,
      height: logoSize,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(context),
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    return Icon(
      Icons.shopping_bag,
      size: logoSize * 0.7,
      color: spinnerColor ?? Theme.of(context).primaryColor,
    );
  }
}