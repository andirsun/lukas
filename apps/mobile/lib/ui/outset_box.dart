import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child] with a negative vertical margin (the web's `-my-3`): it takes [vertical] px less room
/// above and below than it is tall, while it keeps drawing, and answering touches, over its whole
/// height. A 44px target can sit in a 20px line this way.
class OutsetBox extends SingleChildRenderObjectWidget {
  const OutsetBox({super.key, required this.vertical, required Widget super.child});

  final double vertical;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOutset(vertical);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderOutset).vertical = vertical;
  }
}

class _RenderOutset extends RenderShiftedBox {
  _RenderOutset(this._vertical) : super(null);

  double _vertical;
  set vertical(double value) {
    if (value == _vertical) return;
    _vertical = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset(0, -_vertical);
    size = constraints.constrain(Size(child.size.width, child.size.height - 2 * _vertical));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child!;
    final box = Rect.fromLTWH(0, -_vertical, child.size.width, child.size.height);
    if (!box.contains(position)) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, -_vertical),
      position: position,
      hitTest: (result, transformed) => child.hitTest(result, position: transformed),
    );
  }
}

/// Lets a touch anywhere on [targetKey]'s box reach it, wherever its ancestors' bounds end. A badge
/// 44px tall sits in a line 20px tall ([OutsetBox]); the line, and every box above it, would turn
/// a touch on the badge's top and bottom away before it got there. Put this above them all (the
/// row's card) and give it the badge's key. A browser does the same for an element that overflows.
class HitTargetBoost extends SingleChildRenderObjectWidget {
  const HitTargetBoost({super.key, required this.targetKey, required Widget super.child});

  final GlobalKey targetKey;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBoost(targetKey);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderBoost).targetKey = targetKey;
  }
}

class _RenderBoost extends RenderProxyBox {
  _RenderBoost(this.targetKey);

  GlobalKey targetKey;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final target = targetKey.currentContext?.findRenderObject();
    if (size.contains(position) && target is RenderBox && target.attached && target.hasSize) {
      final transform = target.getTransformTo(this);
      final inverse = Matrix4.tryInvert(transform);
      if (inverse != null) {
        final local = MatrixUtils.transformPoint(inverse, position);
        if ((Offset.zero & target.size).contains(local)) {
          final hit = result.addWithPaintTransform(
            transform: transform,
            position: position,
            hitTest: (result, transformed) => target.hitTest(result, position: transformed),
          );
          if (hit) return true;
        }
      }
    }
    return super.hitTest(result, position: position);
  }
}
