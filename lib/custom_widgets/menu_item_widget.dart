import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MenuItemWidget extends StatelessWidget {
  final String iconPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: TextDirection.rtl, // محاذاة من اليمين لليسار
            children: [
              if (iconPath.endsWith('.svg'))
                SvgPicture.asset(
                  iconPath,
                  width: 50,
                  height: 50,
                )
              else
                Image.asset(
                  iconPath,
                  width: 50,
                  height: 50,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl, // محاذاة من اليمين لليسار
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection:
                          TextDirection.rtl, // محاذاة من اليمين لليسار
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textDirection:
                            TextDirection.rtl, // محاذاة من اليمين لليسار
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios), // تغيير اتجاه السهم
            ],
          ),
        ),
      ),
    );
  }
}
