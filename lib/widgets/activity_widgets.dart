import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../theme/app_theme.dart';

/// 深呼吸活动组件
class BreathingActivity extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  
  const BreathingActivity({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<BreathingActivity> createState() => _BreathingActivityState();
}

class _BreathingActivityState extends State<BreathingActivity>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _progressController;
  late Animation<double> _breathAnimation;
  late Animation<double> _progressAnimation;
  
  int _currentCycle = 0;
  final int _totalCycles = 4;
  String _currentPhase = '准备开始';
  bool _isActive = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _breathController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(seconds: _totalCycles * 8),
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);
    
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentCycle++;
        if (_currentCycle < _totalCycles) {
          setState(() {
            _currentPhase = '第 ${_currentCycle + 1} 轮';
          });
          _breathController.reset();
          _breathController.forward();
        } else {
          _completeActivity();
        }
      }
    });
    
    // 优化：减少频繁的setState调用
    _breathAnimation.addListener(() {
      final newPhase = _breathAnimation.value > 1.0 ? '吸气...' : '呼气...';
      if (newPhase != _currentPhase) {
        setState(() {
          _currentPhase = newPhase;
        });
      }
    });
  }
  
  void _startActivity() {
    setState(() {
      _isActive = true;
      _currentPhase = '第 1 轮';
    });
    _breathController.repeat(reverse: true);
    _progressController.forward();
  }
  
  void _completeActivity() {
    _breathController.stop();
    _progressController.stop();
    if (mounted) {
      widget.onComplete();
    }
  }
  
  @override
  void dispose() {
    _breathController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = ActivityTheme.themes['breathing']!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTheme.spacingL),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '深呼吸练习',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    if (mounted) {
                      _breathController.stop();
                      _progressController.stop();
                      widget.onCancel();
                    }
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: AppTheme.animationMedium.inMilliseconds.ms),
            
            const SizedBox(height: AppTheme.spacingL),
            
            if (!_isActive) ..._buildStartScreen() else ..._buildActiveScreen(),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildStartScreen() {
    return [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Icon(
          Icons.air,
          color: Colors.white,
          size: 48,
        ),
      ).animate().scale(duration: 800.ms, curve: AppTheme.animationBounceCurve),
      
      const SizedBox(height: AppTheme.spacingL),
      
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          '让我们一起进行4轮深呼吸\n每轮8秒，放松身心',
          style: AppTheme.bodyLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ).animate().fadeIn(delay: 300.ms, duration: AppTheme.animationMedium.inMilliseconds.ms),
    ];
  }
  
  List<Widget> _buildActiveScreen() {
    return [
      // 进度指示器
      AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progressAnimation.value,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // 呼吸动画圆圈
      AnimatedBuilder(
        animation: _breathAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _breathAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      // 当前阶段文本
      Text(
        _currentPhase,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ).animate().fadeIn(),
      
      const SizedBox(height: 8),
      
      Text(
        '${_currentCycle + 1} / $_totalCycles',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    ];
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_isActive) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (mounted) {
                  _breathController.stop();
                  _progressController.stop();
                  widget.onCancel();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _startActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ActivityTheme.themes['breathing']!.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('开始练习'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _breathController.stop();
                _progressController.stop();
                setState(() {
                  _isActive = false;
                  _currentCycle = 0;
                  _currentPhase = '准备开始';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('停止练习'),
            ),
          ),
        ],
      ],
    );
  }
}

/// 喝水提醒活动组件
class DrinkWaterActivity extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  
  const DrinkWaterActivity({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<DrinkWaterActivity> createState() => _DrinkWaterActivityState();
}

class _DrinkWaterActivityState extends State<DrinkWaterActivity>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late ConfettiController _confettiController;
  
  bool _isCompleted = false;
  double _waterLevel = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fillController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }
  
  void _drinkWater() {
    _fillController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isCompleted = true;
        });
        _confettiController.play();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = ActivityTheme.themes['water']!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTheme.spacingL),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.shadowStrong,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 关闭按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '补充水分',
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        if (mounted) {
                          _waveController.stop();
                          _fillController.stop();
                          widget.onCancel();
                        }
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: AppTheme.animationMedium.inMilliseconds.ms),
                
                const SizedBox(height: AppTheme.spacingL),
                
                _buildWaterGlass(),
                
                const SizedBox(height: AppTheme.spacingL),
                
                if (!_isCompleted) ..._buildInstructions() else ..._buildCompletion(),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                _buildActionButtons(),
              ],
            ),
            
            // 庆祝动画
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.05,
              ),
            ),
          ],
        ),
       ),
    );
  }
  
  Widget _buildWaterGlass() {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _fillController]),
      builder: (context, child) {
        return Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(17),
              bottomRight: Radius.circular(17),
            ),
            child: Stack(
              children: [
                // 水位
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: 120 * _fillController.value,
                    color: Colors.lightBlue.withOpacity(0.7),
                  ),
                ),
                // 波浪效果
                if (_fillController.value > 0)
                  Positioned(
                    bottom: 120 * _fillController.value - 10,
                    left: -50 + (100 * _waveController.value),
                    child: Container(
                      width: 200,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildInstructions() {
    return [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Icon(
          Icons.local_drink,
          color: Colors.white,
          size: 48,
        ),
      ).animate().scale(duration: 800.ms, curve: AppTheme.animationBounceCurve),
      
      const SizedBox(height: AppTheme.spacingL),
      
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          '喝一杯水，补充身体水分\n让大脑更加清醒',
          style: AppTheme.bodyLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ).animate().fadeIn(delay: 300.ms, duration: AppTheme.animationMedium.inMilliseconds.ms),
    ];
  }
  
  List<Widget> _buildCompletion() {
    return [
      const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 40,
      ).animate().scale(duration: 500.ms),
      
      const SizedBox(height: 12),
      
      AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            '太棒了！\n身体得到了很好的补充',
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            speed: const Duration(milliseconds: 80),
          ),
        ],
        totalRepeatCount: 1,
      ),
    ];
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_isCompleted) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (mounted) {
                  _waveController.stop();
                  _fillController.stop();
                  widget.onCancel();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _drinkWater,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ActivityTheme.themes['water']!.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('我喝了'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ActivityTheme.themes['water']!.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('完成'),
            ),
          ),
        ],
      ],
    );
  }
}

/// 伸展运动活动组件
class StretchActivity extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  
  const StretchActivity({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<StretchActivity> createState() => _StretchActivityState();
}

class _StretchActivityState extends State<StretchActivity>
    with TickerProviderStateMixin {
  late AnimationController _stretchController;
  late AnimationController _timerController;
  late ConfettiController _confettiController;
  
  final List<String> _exercises = [
    '颈部左右转动',
    '肩膀上下耸动',
    '手臂伸展',
    '腰部扭转',
  ];
  
  int _currentExercise = 0;
  bool _isActive = false;
  bool _isCompleted = false;
  int _remainingTime = 15;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _stretchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _timerController.addListener(() {
      setState(() {
        _remainingTime = (15 * (1 - _timerController.value)).round();
      });
    });
    
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextExercise();
      }
    });
  }
  
  void _startActivity() {
    setState(() {
      _isActive = true;
    });
    _startCurrentExercise();
  }
  
  void _startCurrentExercise() {
    _stretchController.repeat(reverse: true);
    _timerController.reset();
    _timerController.forward();
  }
  
  void _nextExercise() {
    _stretchController.stop();
    
    if (_currentExercise < _exercises.length - 1) {
      setState(() {
        _currentExercise++;
        _remainingTime = 15;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _startCurrentExercise();
      });
    } else {
      _completeActivity();
    }
  }
  
  void _completeActivity() {
    if (mounted) {
      setState(() {
        _isCompleted = true;
      });
      _confettiController.play();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _stretchController.dispose();
    _timerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = ActivityTheme.themes['stretch']!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTheme.spacingL),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.shadowStrong,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 关闭按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '伸展运动',
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        if (mounted) {
                          _stretchController.stop();
                          _timerController.stop();
                          widget.onCancel();
                        }
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: AppTheme.animationMedium.inMilliseconds.ms),
                
                const SizedBox(height: AppTheme.spacingL),
                
                if (!_isActive) ..._buildStartScreen(),
                if (_isActive && !_isCompleted) ..._buildActiveScreen(),
                if (_isCompleted) ..._buildCompletionScreen(),
                
                const SizedBox(height: AppTheme.spacingXL),
                
                _buildActionButtons(),
              ],
            ),
            
            // 庆祝动画
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildStartScreen() {
    return [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Icon(
          Icons.self_improvement,
          color: Colors.white,
          size: 48,
        ),
      ).animate().scale(duration: 800.ms, curve: AppTheme.animationBounceCurve),
      
      const SizedBox(height: AppTheme.spacingL),
      
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          '4个简单的伸展动作\n每个15秒，放松肌肉',
          style: AppTheme.bodyLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ).animate().fadeIn(delay: 300.ms, duration: AppTheme.animationMedium.inMilliseconds.ms),
    ];
  }
  
  List<Widget> _buildActiveScreen() {
    return [
      // 进度指示器
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_exercises.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index <= _currentExercise 
                  ? Colors.white 
                  : Colors.white30,
            ),
          );
        }),
      ),
      
      const SizedBox(height: 20),
      
      // 动作演示
      AnimatedBuilder(
        animation: _stretchController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _stretchController.value * 0.5,
            child: const Icon(
              Icons.accessibility_new,
              color: Colors.white,
              size: 80,
            ),
          );
        },
      ),
      
      const SizedBox(height: 20),
      
      Text(
        _exercises[_currentExercise],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ).animate().fadeIn(),
      
      const SizedBox(height: 12),
      
      // 倒计时
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$_remainingTime 秒',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }
  
  List<Widget> _buildCompletionScreen() {
    return [
      const Icon(
        Icons.emoji_events,
        color: Colors.white,
        size: 80,
      ).animate().scale(duration: 800.ms),
      
      const SizedBox(height: 16),
      
      AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            '完美！\n您的身体得到了很好的放松',
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            speed: const Duration(milliseconds: 80),
          ),
        ],
        totalRepeatCount: 1,
      ),
    ];
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_isActive) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (mounted) {
                  _stretchController.stop();
                  _timerController.stop();
                  widget.onCancel();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _startActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ActivityTheme.themes['stretch']!.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('开始练习'),
            ),
          ),
        ] else if (_isCompleted) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ActivityTheme.themes['stretch']!.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('完成'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _stretchController.stop();
                _timerController.stop();
                setState(() {
                   _isActive = false;
                   _currentExercise = 0;
                   _remainingTime = 15;
                 });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
              child: const Text('停止练习'),
            ),
          ),
        ],
      ],
    );
  }
}