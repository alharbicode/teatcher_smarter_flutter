import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/math_provider.dart';
import '../../models_for_api/math_model_api.dart';
import '../../custom_widgets/custom_app_bar.dart';
import '../../models/math_model.dart';
import '../../app_themes/app_colors.dart';
import '../../custom_widgets/CustomPositionedElements.dart';

class OperationExamplesScreen extends StatefulWidget {
  final int operationType;
  final String operationLabel;
  final int level;

  const OperationExamplesScreen({
    super.key,
    required this.operationType,
    required this.operationLabel,
    required this.level,
  });

  @override
  _OperationExamplesScreenState createState() =>
      _OperationExamplesScreenState();
}

class _OperationExamplesScreenState extends State<OperationExamplesScreen> with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late FlutterTts flutterTts;
  bool _showExample = false;
  bool _isReading = false;
  bool _audioEnabled = true;
  double _speechRate = 0.5;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _loadPreferences();
    _initTts();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mathProvider = context.read<MathProvider>();
      switch (widget.operationType) {
        case 0:
          mathProvider.filterByOperationAndLevel(
              Operation.addition, widget.level);
          break;
        case 1:
          mathProvider.filterByOperationAndLevel(
              Operation.subtraction, widget.level);
          break;
        case 2:
          mathProvider.filterByOperationAndLevel(
              Operation.multiplication, widget.level);
          break;
        case 3:
          mathProvider.filterByOperationAndLevel(
              Operation.division, widget.level);
          break;
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble('math_speech_rate') ?? 0.5;
      _audioEnabled = prefs.getBool('math_audio_enabled') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('math_speech_rate', _speechRate);
    await prefs.setBool('math_audio_enabled', _audioEnabled);
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(_speechRate);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    });
  }

  Future<void> _speak(String text) async {
    if (!_audioEnabled) return;
    
    setState(() {
      _isReading = true;
    });
    await flutterTts.speak(text);
    
    // Start animation
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final currentMath = context.read<MathProvider>().currentMath;
    if (currentMath != null &&
        _currentStepIndex < currentMath.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _speak(currentMath.steps[_currentStepIndex]);
      
      // Scroll to make current step visible
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _currentStepIndex * 80.0, // Approximate height of each step
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _speak(
          context.read<MathProvider>().currentMath!.steps[_currentStepIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تعلم ${widget.operationLabel}',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Consumer<MathProvider>(
            builder: (context, mathProvider, child) {
              if (mathProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentMath = mathProvider.currentMath;
              if (currentMath == null) {
                return const Center(child: Text('لا توجد أمثلة متاحة'));
              }

              if (!_showExample) {
                return _buildExamplesList(mathProvider);
              }

              return _buildExampleDetails(currentMath);
            },
          ),
          // Add decorative elements
          CustomPositionedElements.starIconTopRight(),
          CustomPositionedElements.fourIconTopLeft(),
          CustomPositionedElements.dashIconTopLeft(),
          CustomPositionedElements.seenIconMiddleLeft(),
          CustomPositionedElements.noonIconBottomLeft(),
          CustomPositionedElements.starIconBottomLeft(),
        ],
      ),
    );
  }

  Widget _buildExamplesList(MathProvider mathProvider) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Speech rate controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Audio toggle switch
                        Row(
                          children: [
                            Switch(
                              value: _audioEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _audioEnabled = value;
                                });
                                _savePreferences();
                              },
                              activeColor: AppColors.accentColor,
                            ),
                            const Text(
                              'الصوت',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        // Speech rate title
                        const Text(
                          'سرعة النطق:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Speech rate buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedButton('بطيء', 0.3, _speechRate <= 0.3),
                        const SizedBox(width: 10),
                        _buildSpeedButton('متوسط', 0.5,
                            _speechRate > 0.3 && _speechRate < 0.7),
                        const SizedBox(width: 10),
                        _buildSpeedButton('سريع', 0.7, _speechRate >= 0.7),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mathProvider.filteredItems.length,
              itemBuilder: (context, index) {
                final example = mathProvider.filteredItems[index];
                return GestureDetector(
                  onTap: () {
                    mathProvider.setCurrentIndex(index);
                    setState(() {
                      _showExample = true;
                      _currentStepIndex = 0;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _speak(mathProvider.currentMath!.steps[0]);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[200]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.chevron_right),
                          Text(
                            '${example.num1}${example.operationSymbol}${example.num2}=?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
   ),
   ],
   ),);
  }

  // Method to build speed buttons
  Widget _buildSpeedButton(String label, double rate, bool isActive) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _speechRate = rate;
        });
        flutterTts.setSpeechRate(_speechRate);
        _savePreferences();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppColors.accentColor : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: isActive ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildExampleDetails(MathModelApi currentMath) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Audio controls in example view
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showExample = false),
                  ),
                  Row(
                    children: [
                      Switch(
                        value: _audioEnabled,
                        onChanged: (value) {
                          setState(() {
                            _audioEnabled = value;
                          });
                          _savePreferences();
                        },
                        activeColor: AppColors.accentColor,
                      ),
                      const Text(
                        'الصوت',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    'مثال تعليمي:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Example equation with animation
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animation.value * 0.05),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${currentMath.num1}${currentMath.operationSymbol}${currentMath.num2}=?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'خطوات الحل:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: currentMath.steps.length,
              itemBuilder: (context, index) {
                final isCurrentStep = index == _currentStepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentStep && _isReading
                        ? AppColors.accentColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrentStep && _isReading
                            ? AppColors.accentColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: isCurrentStep && _isReading
                              ? AppColors.accentColor
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          currentMath.steps[index],
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: isCurrentStep && _isReading
                                ? AppColors.accentColor
                                : Colors.black87,
                            fontWeight: isCurrentStep && _isReading
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: _currentStepIndex > 0 ? _previousStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.all(8),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 4),
                      Text('السابق', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: () => _speak(currentMath.steps[_currentStepIndex]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    padding: const EdgeInsets.all(8),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isReading ? Icons.volume_up : Icons.volume_up_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isReading ? 'جاري...' : 'استماع',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: ElevatedButton(
                  onPressed: _currentStepIndex < currentMath.steps.length - 1
                      ? _nextStep
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.all(8),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('التالي', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  }

