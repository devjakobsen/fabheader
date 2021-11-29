import 'dart:ui';

import 'package:flutter/material.dart';

enum FabStyle {
  stickyHeader,
  stickyHeaderParralax,
  scrollUp,
}

class FabHeader extends StatefulWidget {
  // floatingChild is positioned on top of the navbar
  final Widget floatingChild;

  // child appends to floatingChild bottom
  final Widget child;

  // shows lines that will help visualise what is happening. Leftside shows a line per 100 px, right side small one is minNavbarHeight and the big one is maxNavbarHeight
  final bool debug;

  // callback on refresh
  final Function? onRefresh;

  // sets the color on navbar
  final Color navbarColor;

  // adds an image from assets or network on top of the navbar - note the color will be redundant.
  final String? navbarImagePath;

  // background image alignment
  final Alignment backgroundImageAlignment;

  // background image overlay color
  final Color? backgroundImageOverlayColor;

  // select what looks crispy? select a style you like
  final FabStyle? style;

  // add your own decoration
  final BoxDecoration? boxDecoration;

  FabHeader({
    Key? key,
    required this.floatingChild,
    required this.child,
    required this.navbarColor,
    this.debug = true,
    this.onRefresh,
    this.navbarImagePath,
    this.backgroundImageAlignment = Alignment.center,
    this.backgroundImageOverlayColor,
    this.style = FabStyle.stickyHeaderParralax,
    this.boxDecoration,
  }) : super(key: key) {
    assert(floatingChild.key is GlobalKey,
        'Add a global key on the floatingChild, like this: Container(key: GlobalKey()) - this is used to calculate the height of the floatingChild');
    assert(child.key is GlobalKey,
        'Add a global key on the child, like this: Container(key: GlobalKey()) - this is used to calculate the height of the child');
    assert(WidgetsBinding.instance != null,
        'Add WidgetsFlutterBinding.ensureInitialized() before calling FabHeader. It could be in main.dart like this: void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const MyApp()); }');
  }

  @override
  State<FabHeader> createState() => _FabHeaderState();
}

class _FabHeaderState extends State<FabHeader> {
  double floatingHeight = 0;
  double childHeight = 0;
  ScrollController? _scrollController;
  bool collapsed = false;
  double maxNavbarHeight = 300;
  double minNavbarHeight = 80;
  double navbarPositionY = 0;
  double navbarHeight = 0;
  double gapWhenChildGoesUnderNavbar = 10;
  double yPos = 0;
  double parralaxEffect = 0;

  @override
  void initState() {
    super.initState();
    navbarHeight = maxNavbarHeight;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController = ScrollController()
        ..addListener(
          () {
            calculatePosition();
            setState(() {});
          },
        );

      // calculate size of floatingChild
      RenderObject? floatingRenderBox = (widget.floatingChild.key as GlobalKey).currentContext?.findRenderObject();
      log('${(floatingRenderBox as RenderBox).size.height}');
      floatingHeight = floatingRenderBox.size.height;
      assert(floatingHeight >= 125, 'The floatingChild needs to float so it is needed to be >= 125');

      // calculate size of child
      RenderObject? childRenderObject = (widget.child.key as GlobalKey).currentContext?.findRenderObject();
      log('${(childRenderObject as RenderBox).size.height}');
      childHeight = childRenderObject.size.height;

      setState(() {});
    });
  }

  void calculatePosition() {
    yPos = _scrollController?.offset ?? 0;
    double trigger = maxNavbarHeight * 0.6 - yPos + gapWhenChildGoesUnderNavbar;
    if (widget.debug) {
      log('\n collapsed: $collapsed \n ypos: ${yPos.abs()} \n trigger: $trigger\n navPostionY: $navbarPositionY  \n minHeight: $minNavbarHeight \n maxHeight: $maxNavbarHeight \n');
    }
    if (trigger <= minNavbarHeight) {
      collapsed = true;
      navbarPositionY =
          widget.style == FabStyle.scrollUp ? navbarPositionY : -(maxNavbarHeight - minNavbarHeight) + yPos;
    } else {
      navbarPositionY = -yPos;
      collapsed = false;
      parralaxEffect = navbarPositionY < 0 ? navbarPositionY.abs() * 2 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        widget.onRefresh != null ? widget.onRefresh!() : null;
        return Future.value();
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        child: SizedBox(
          height: maxNavbarHeight +
              gapWhenChildGoesUnderNavbar +
              floatingHeight +
              gapWhenChildGoesUnderNavbar +
              childHeight,
          child: Stack(
            alignment: Alignment.topCenter,
            children: _buildChildren(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    return !collapsed
        ? [
            _buildNavbarCover(),
            _buildChildUnderFloating(),
            _buildFloatingChild(),
            _debug(yPos, minNavbarHeight, maxNavbarHeight)
          ]
        : [
            _buildChildUnderFloating(),
            _buildFloatingChild(),
            _buildNavbarCover(),
            _debug(yPos, minNavbarHeight, maxNavbarHeight)
          ];
  }

  _buildFloatingChild() {
    return Positioned(
      top: maxNavbarHeight * 0.6 + gapWhenChildGoesUnderNavbar * 2,
      child: widget.floatingChild,
    );
  }

  _buildChildUnderFloating() {
    return Positioned(
      top: floatingHeight + maxNavbarHeight * 0.6 + gapWhenChildGoesUnderNavbar * 4,
      child: widget.child,
    );
  }

  _buildNavbarCover() {
    return Positioned(
      top: navbarPositionY,
      left: 0,
      right: 0,
      child: SizedBox(
          height: maxNavbarHeight,
          child: Container(
            margin: EdgeInsets.only(
              top: widget.style == FabStyle.stickyHeaderParralax ? parralaxEffect : 0,
            ),
            decoration: widget.boxDecoration?.copyWith(
                  image: _buildNavbarDecoratingImage(),
                ) ??
                BoxDecoration(
                  image: _buildNavbarDecoratingImage(),
                  color: widget.navbarColor,
                ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: yPos < 0 ? yPos.abs() / 2 : -1,
                sigmaY: yPos < 0 ? yPos.abs() / 2 : -1,
              ),
              child: Container(
                color: widget.backgroundImageOverlayColor ?? Colors.black.withOpacity(0.5),
              ),
            ),
          )),
    );
  }

  _buildNavbarDecoratingImage() {
    if (widget.navbarImagePath != null) {
      if (widget.navbarImagePath!.contains('http')) {
        return DecorationImage(
          image: NetworkImage(
            widget.navbarImagePath!,
          ),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: AssetImage(
            widget.navbarImagePath!,
          ),
          fit: BoxFit.cover,
        );
      }
    } else {
      return null;
    }
  }

  Widget _debug(
    double yPos,
    double minNavbarHeight,
    double maxNavbarHeight,
  ) {
    return widget.debug
        ? Stack(children: [
            // Debug
            Positioned(
              left: 5,
              top: yPos,
              child: Container(
                height: 100,
                width: 5,
                color: Colors.black,
              ),
            ),
            Positioned(
              left: 5,
              top: yPos + 100,
              child: Container(
                height: 100,
                width: 5,
                color: Colors.deepOrange,
              ),
            ),
            Positioned(
              left: 5,
              top: yPos + 200,
              child: Container(
                height: 100,
                width: 5,
                color: Colors.blueGrey,
              ),
            ),
            Positioned(
              left: 5,
              top: yPos + 300,
              child: Container(
                height: 100,
                width: 5,
                color: Colors.cyan,
              ),
            ),
            Positioned(
              left: 5,
              top: yPos + 400,
              child: Container(
                height: 100,
                width: 5,
                color: Colors.pinkAccent,
              ),
            ),
            // min header
            Positioned(
              right: 15,
              top: yPos,
              child: Container(
                height: minNavbarHeight,
                width: 5,
                color: Colors.pinkAccent,
              ),
            ),
            // max header
            Positioned(
              right: 5,
              top: yPos,
              child: Container(
                height: maxNavbarHeight,
                width: 5,
                color: Colors.pinkAccent,
              ),
            ),
          ])
        : Container();
  }
}

void log(String log) {
  debugPrint('\n ********* $log *********');
}
