import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A box that paints its [decoration] the way Chrome paints a CSS box: with its left, top, right
/// and bottom edges rounded to whole device pixels. Layout keeps the fractions (a 102.67px column,
/// a 30.5px pill) and the text inside stays where the fractions put it, but the box, its border
/// and its shadow are drawn on the pixel grid, so their edges are sharp and are the same ones the
/// web's picture has. Flutter draws a fractional edge anti-aliased across two pixels.
class SnappedDecoratedBox extends SingleChildRenderObjectWidget {
  const SnappedDecoratedBox({super.key, required this.decoration, super.child});

  final Decoration decoration;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSnapped(
    decoration,
    MediaQuery.devicePixelRatioOf(context),
    Directionality.maybeOf(context) ?? TextDirection.ltr,
  );

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderSnapped)
      ..decoration = decoration
      ..ratio = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderSnapped extends RenderProxyBox {
  _RenderSnapped(this._decoration, this._ratio, this._direction);

  Decoration _decoration;
  double _ratio;
  final TextDirection _direction;
  BoxPainter? _painter;

  set decoration(Decoration value) {
    if (value == _decoration) return;
    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  set ratio(double value) {
    if (value == _ratio) return;
    _ratio = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final global = localToGlobal(Offset.zero);
    double snap(double value) => (value * _ratio).round() / _ratio;
    final left = snap(global.dx);
    final top = snap(global.dy);
    final rect = Rect.fromLTRB(
      left,
      top,
      snap(global.dx + size.width),
      snap(global.dy + size.height),
    ).shift(-global);
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);
    _painter!.paint(
      context.canvas,
      offset + rect.topLeft,
      ImageConfiguration(size: rect.size, textDirection: _direction),
    );
    super.paint(context, offset);
  }
}
