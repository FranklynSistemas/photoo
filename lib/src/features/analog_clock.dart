import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  const AnalogClock({super.key});

  @override
  AnalogClockState createState() => AnalogClockState();
}

class AnalogClockState extends State<AnalogClock> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: CustomPaint(
        painter: ClockPainter(_currentTime),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime time;

  ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Transparent background (no fill)
    final backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw minute markers (dots only between hours)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final startAngle = i * 30; // Starting angle of the current hour section
      for (int j = 1; j <= 4; j++) {
        // Minute dots between the hours: 6°, 12°, 18°, 24° relative to the startAngle
        final angle = (startAngle + j * 6) * pi / 180;
        final dotOffsetX = center.dx + radius * 0.8 * sin(angle);
        final dotOffsetY = center.dy - radius * 0.8 * cos(angle);
        canvas.drawCircle(Offset(dotOffsetX, dotOffsetY), 2, dotPaint);
      }
    }

    // Draw hour numbers
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final bigTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black, // Black border
    );

    const bigTextInnerStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white, // White inside
    );
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = i * 30 * pi / 180; // Convert hours to radians
      final offsetX = center.dx + radius * 0.8 * sin(angle);
      final offsetY = center.dy - radius * 0.8 * cos(angle);
      textPainter.text = TextSpan(
        text: i.toString(),
        style: i % 3 == 0 ? bigTextStyle : textStyle,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            offsetX - textPainter.width / 2, offsetY - textPainter.height / 2),
      );

      if (i % 3 == 0) {
        textPainter.text = TextSpan(
          text: i.toString(),
          style: bigTextInnerStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(offsetX - textPainter.width / 2,
              offsetY - textPainter.height / 2),
        );
      }
    }

    // Draw the clock hands
    final handPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Hour hand
    final hourAngle = (time.hour % 12) * 30 + (time.minute * 0.5);
    _drawHand(canvas, center, radius * 0.5, hourAngle, handPaint);

    // Minute hand
    final minuteAngle = time.minute * 6;
    _drawHand(canvas, center, radius * 0.7, minuteAngle.toDouble(), handPaint);

    // Second hand
    final secondHandPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;
    final secondAngle = time.second * 6;
    _drawHand(
        canvas, center, radius * 0.7, secondAngle.toDouble(), secondHandPaint);
  }

  void _drawHand(
      Canvas canvas, Offset center, double length, double angle, Paint paint) {
    final angleRad = angle * pi / 180; // Use 'pi' from 'dart:math'
    final handEnd = Offset(
      center.dx + length * sin(angleRad),
      center.dy - length * cos(angleRad),
    );
    // Draw the main line of the hand
    canvas.drawLine(center, handEnd, paint);

    // // Now, let's draw the arrow at the tip of the hand
    // const arrowSize = 10.0; // Size of the arrowhead
    // const arrowAngle = pi / 6; // 30 degrees for the arrow's sides

    // // Calculate the points for the arrowhead based on the hand's angle
    // final arrowPoint1 = Offset(
    //   handEnd.dx +
    //       arrowSize * cos(angleRad + arrowAngle), // Right side of the arrow
    //   handEnd.dy + arrowSize * sin(angleRad + arrowAngle),
    // );

    // final arrowPoint2 = Offset(
    //   handEnd.dx +
    //       arrowSize * cos(angleRad - arrowAngle), // Left side of the arrow
    //   handEnd.dy + arrowSize * sin(angleRad - arrowAngle),
    // );

    // // Create the arrowhead path (triangle)
    // final arrowPath = Path()
    //   ..moveTo(
    //       handEnd.dx, handEnd.dy) // Tip of the hand (center of the arrowhead)
    //   ..lineTo(arrowPoint1.dx, arrowPoint1.dy) // Right side of the arrowhead
    //   ..lineTo(arrowPoint2.dx, arrowPoint2.dy) // Left side of the arrowhead
    //   ..close(); // Close the path to form the triangle

    // // Draw the arrowhead at the tip of the hand
    // canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
