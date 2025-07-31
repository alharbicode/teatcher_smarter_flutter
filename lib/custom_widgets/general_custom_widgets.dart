import 'package:flutter/material.dart';

/// ويدجت لعرض النص التعليمي وجملة المهمة
class InstructionTextWidget extends StatelessWidget {
  final String title;
  final String sentenceText;
  final Color titleColor;
  final Color sentenceColor;
  final double titleFontSize;
  final double sentenceFontSize;

  const InstructionTextWidget({
    super.key,
    required this.title,
    required this.sentenceText,
    required this.titleColor,
    required this.sentenceColor,
    required this.titleFontSize,
    required this.sentenceFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 14),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.13),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          if (sentenceText.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              sentenceText,
              style: TextStyle(
                fontSize: sentenceFontSize,
                fontWeight: FontWeight.bold,
                color: sentenceColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ويدجت لعرض الجملة المرتبة
class SortedSentenceWidget extends StatelessWidget {
  final List<String> selectedWords;
  final Color textColor;
  final double fontSize;
  final String placeholder;

  const SortedSentenceWidget({
    super.key,
    required this.selectedWords,
    required this.textColor,
    required this.fontSize,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        selectedWords.isEmpty ? placeholder : selectedWords.join(' '),
        style: TextStyle(fontSize: fontSize, color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// ويدجت لعرض الكلمات المبعثرة
class ShuffledWordsWidget extends StatelessWidget {
  final List<String> shuffledWords;
  final List<String> selectedWords;
  final Function(String) onWordTapped;
  final Color buttonColor;
  final Color selectedButtonColor;
  final Color textColor;
  final double fontSize;

  const ShuffledWordsWidget({
    super.key,
    required this.shuffledWords,
    required this.selectedWords,
    required this.onWordTapped,
    required this.buttonColor,
    required this.selectedButtonColor,
    required this.textColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: shuffledWords.map((word) {
        bool isSelected = selectedWords.contains(word);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? selectedButtonColor : buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: isSelected ? 4 : 1,
            shadowColor: Colors.grey.withOpacity(0.15),
          ),
          onPressed: () => onWordTapped(word),
          child: Text(
            word,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ويدجت زر الاستماع
class ListenButtonWidget extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;
  final String buttonText;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color buttonColor;
  final EdgeInsets padding;

  const ListenButtonWidget({
    super.key,
    required this.isProcessing,
    required this.onPressed,
    required this.buttonText,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.buttonColor,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isProcessing ? null : onPressed,
      icon: Icon(icon, color: iconColor, size: 32),
      label: Text(buttonText, style: TextStyle(color: textColor, fontSize: 22)),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: padding.add(EdgeInsets.symmetric(vertical: 8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),
    );
  }
}

/// ويدجت زر التحقق
class CheckButtonWidget extends StatelessWidget {
  final bool isProcessing;
  final bool isButtonEnabled;
  final VoidCallback onPressed;
  final String buttonText;
  final IconData icon;
  final Color buttonColor;
  final Color textColor;
  final EdgeInsets padding;

  const CheckButtonWidget({
    super.key,
    required this.isProcessing,
    required this.isButtonEnabled,
    required this.onPressed,
    required this.buttonText,
    required this.icon,
    required this.buttonColor,
    required this.textColor,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: ElevatedButton(
        onPressed: !isProcessing && isButtonEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: padding.add(EdgeInsets.symmetric(vertical: 8)),
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(width: 10),
            Icon(icon, color: textColor),
          ],
        ),
      ),
    );
  }
}

/// ويدجت أزرار التنقل (السابق والتالي)
class NavigationButtonsWidget extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final String previousButtonText;
  final String nextButtonText;
  final IconData previousIcon;
  final IconData nextIcon;
  final Color activeColor;
  final Color inactiveColor;
  final EdgeInsets padding;

  const NavigationButtonsWidget({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.previousButtonText,
    required this.nextButtonText,
    required this.previousIcon,
    required this.nextIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: ElevatedButton(
              onPressed: hasPrevious ? onPreviousPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPrevious ? activeColor : inactiveColor,
                padding: padding.add(EdgeInsets.symmetric(vertical: 8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(previousIcon, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    previousButtonText,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 40),
          Flexible(
            flex: 1,
            child: ElevatedButton(
              onPressed: hasNext ? onNextPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasNext ? activeColor : inactiveColor,
                padding: padding.add(EdgeInsets.symmetric(vertical: 8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextButtonText,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(nextIcon, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ويدجت لعرض الكلمة المجمعة
class AssembledWordWidget extends StatelessWidget {
  final String assembledWord;
  final Color textColor;
  final double fontSize;
  final String placeholder;

  const AssembledWordWidget({
    super.key,
    required this.assembledWord,
    required this.textColor,
    required this.fontSize,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.13),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        assembledWord.isEmpty ? placeholder : assembledWord,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

/// ويدجت لعرض الحرف
class LetterWidget extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color defaultColor;
  final double fontSize;

  const LetterWidget({
    super.key,
    required this.letter,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.defaultColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : defaultColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.18),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
