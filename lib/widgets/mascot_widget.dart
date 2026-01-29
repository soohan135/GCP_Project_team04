import 'package:flutter/material.dart';

enum MascotType { user, center }

enum MascotExpression { happy, thinking, waiting }

class MascotWidget extends StatefulWidget {
  final String? message;
  final MascotType type;
  final MascotExpression expression;

  const MascotWidget({
    super.key,
    this.message,
    required this.type,
    this.expression = MascotExpression.happy,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.message != null) _buildSpeechBubble(),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _controller.value * -10),
              child: widget.type == MascotType.user
                  ? _buildUserMascot()
                  : _buildCenterMascot(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpeechBubble() {
    final bool isUser = widget.type == MascotType.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomRight: Radius.circular(isUser ? 24 : 4),
          bottomLeft: Radius.circular(isUser ? 4 : 24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUser ? Colors.lightBlue.shade50 : Colors.orange.shade50,
          width: 2,
        ),
      ),
      child: Text(
        widget.message!,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey.shade800,
        ),
      ),
    );
  }

  Widget _buildUserMascot() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body
          Container(
            width: 80,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.lightBlue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Eyes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserEye(),
                    const SizedBox(width: 12),
                    _buildUserEye(),
                  ],
                ),
                // Mouth
                Positioned(
                  bottom: 15,
                  child: Container(
                    width: 16,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blueGrey.shade800,
                          width: 2,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Antenna
          Positioned(
            top: 0,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 2, height: 10, color: Colors.grey.shade400),
              ],
            ),
          ),
          // Arms
          Positioned(
            left: 0,
            top: 40,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 12,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade600,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 40,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 12,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade600,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserEye() {
    if (widget.expression == MascotExpression.thinking) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: 10,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Align(
        alignment: const Alignment(-0.5, -0.5),
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMascot() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bolt Body (Orange/Yellow theme)
          Container(
            width: 90,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueGrey.shade800, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 65,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueGrey.shade800.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCenterEye(),
                    const SizedBox(width: 8),
                    _buildCenterEye(),
                  ],
                ),
              ),
            ),
          ),
          // Ears (Yellow)
          Positioned(
            left: 0,
            top: 40,
            child: Container(
              width: 12,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.yellow,
                border: Border.all(color: Colors.blueGrey.shade800, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 40,
            child: Container(
              width: 12,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.yellow,
                border: Border.all(color: Colors.blueGrey.shade800, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Lightning Antenna
          Positioned(
            top: 0,
            child: Transform.rotate(
              angle: 0.1,
              child: const Icon(
                Icons.bolt,
                color: Colors.yellow,
                size: 32,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterEye() {
    if (widget.expression == MascotExpression.thinking) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blueGrey.shade800,
            width: 3,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      );
    }
    return Container(
      width: 12,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: const Alignment(0.5, -0.5),
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
