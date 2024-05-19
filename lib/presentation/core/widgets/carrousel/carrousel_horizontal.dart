import 'package:flutter/material.dart';

class CarrouselHorizontal extends StatefulWidget {
  const CarrouselHorizontal(
      {super.key,
      required this.children,
      this.crossAxisCount = 2,
      this.mainAxisCount = 3,
      this.width = 300,
      this.spacing = 20,
      this.runSpacing = 20});

  final int crossAxisCount;
  final int mainAxisCount;
  final double spacing;
  final double runSpacing;
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

    return SizedBox(
      width: widget.width + 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              onPressed: handlePrevious,
              icon: Icon(
                size: 28,
                color: _currentPage == 1 ? colorDisabled : color,
                Icons.arrow_back_ios_new_rounded,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            width: widget.width,
            child: CustomScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              slivers: <Widget>[
                SliverGrid.count(
                  crossAxisCount: widget.crossAxisCount,
                  children: widget.children,
                )
              ],
            ),
          ),
          Positioned(
            right: -5,
            child: IconButton(
              onPressed: handleNext,
              icon: Icon(
                size: 28,
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
    print(widget.children.length);
    print(widget.mainAxisCount * widget.crossAxisCount);
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
