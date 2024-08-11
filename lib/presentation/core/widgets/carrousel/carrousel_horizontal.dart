import 'package:flutter/material.dart';

class CarrouselHorizontal extends StatefulWidget {
  const CarrouselHorizontal(
      {super.key,
      required this.children,
      this.crossAxisCount = 2,
      this.mainAxisCount = 3,
      this.height = 200,
      this.width = 400});

  final int crossAxisCount;
  final int mainAxisCount;
  final double height;
  final double width;
  final List<Widget> children;

  @override
  State<StatefulWidget> createState() => _CarrouselHorizontal();
}

class _CarrouselHorizontal extends State<CarrouselHorizontal> {
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    const color = Color.fromRGBO(159, 121, 249, 1);
    const colorDisabled = Color.fromRGBO(203, 178, 255, 1);

    return Container(
      height: widget.height,
      width: widget.width,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -14,
            child: IconButton(
              iconSize: 28,
              onPressed: handlePrevious,
              icon: Icon(
                color: _currentPage == 1 ? colorDisabled : color,
                Icons.arrow_back_ios_new_rounded,
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.crossAxisCount),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => widget.children[index],
                    childCount: widget.children.length,
                  ),
                ),
              )
            ],
          ),
          Positioned(
            right: -14,
            child: IconButton(
              onPressed: handleNext,
              iconSize: 28,
              icon: Icon(
                color: (_currentPage ==
                            (widget.children.length /
                                    (widget.mainAxisCount *
                                        widget.crossAxisCount))
                                .round()) ||
                        (widget.children.length >
                            widget.mainAxisCount * widget.crossAxisCount)
                    ? colorDisabled
                    : color,
                Icons.arrow_forward_ios_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void handlePrevious() {
    if (_currentPage == 1) return;

    _scrollController.animateTo(_scrollController.offset - widget.width,
        duration: const Duration(milliseconds: 300), curve: Curves.easeIn);

    setState(() {
      _currentPage--;
    });
  }

  void handleNext() {
    if (_currentPage ==
            (widget.children.length /
                    (widget.mainAxisCount * widget.crossAxisCount))
                .round() ||
        widget.children.length > widget.mainAxisCount * widget.crossAxisCount) {
      return;
    }

    _scrollController.animateTo(_scrollController.offset + widget.width,
        duration: const Duration(milliseconds: 300), curve: Curves.easeIn);

    setState(() {
      _currentPage++;
    });
  }
}
