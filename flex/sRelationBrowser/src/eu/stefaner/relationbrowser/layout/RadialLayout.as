﻿package eu.stefaner.relationbrowser.layout
{
  import eu.stefaner.relationbrowser.ui.Node;
  
  import flare.query.methods.eq;
  import flare.vis.data.DataList;
  import flare.vis.data.NodeSprite;
  import flare.vis.operator.layout.Layout;
  
  import flash.display.DisplayObjectContainer;

  /**
   * @author mo
   */
  public class RadialLayout extends Layout
  {

    public var sortBy:Array;
    private var innerRadius:int = 0;

    public function RadialLayout(sortBy:Array = null, innerRadius:int = 240)
    {
      this.innerRadius = innerRadius;
      this.sortBy = sortBy ? sortBy : [];
      layoutType = Layout.CARTESIAN;
    }

    protected override function layout():void
    {
      autoAnchor();

      var selectedNode:Node = (layoutRoot as Node);
      var r:Number = .5 * Math.max(visualization.bounds.width, visualization.bounds.height);
      visualization.data.nodes.setProperties(
      {
        radius: r,
        origin: _anchor
      }, _t);

      _t.$(selectedNode).radius = .001;
      var innerRing:DataList = new DataList("inner");
      var outerRing:DataList = new DataList("outer");

      visualization.data.group("visibleNodes").visit(function(n:Node):void
      {
        if(n == selectedNode)
        {
          return;
        }

        else if(n.props.distance == 1)
        {
          innerRing.add(n);
        }

        else
        {
          outerRing.add(n);
        }
      });

      innerRing.sortBy(sortBy);
      outerRing.sortBy(sortBy);

      var angleInc:Number = (Math.PI * 2.0) / innerRing.length;
      var counter:uint = innerRing.length;
      var n:Node;

      var doZigZag:uint = 0;

      if(innerRing.length > 10)
      {
        doZigZag = 1;
      }

      var angle:Number;

      for each(n in innerRing)
      {
        _t.$(n).radius = innerRadius + doZigZag * ((counter % 2) * 2 - 1) * innerRadius / 6;
        angle = angleInc * counter--;
        _t.$(n).angle = angle;
        n.parent.addChild(n);
      }

      angleInc = (Math.PI * 2.0) / outerRing.length;
      counter = outerRing.length;

      for each(n in outerRing)
      {
        // TODO: introduce outerradius var, express as fraction of layoutBounds.width
        _t.$(n).radius = innerRadius * .5 + innerRadius * .5 * n.props.distance;
        angle = angleInc * counter--;
        _t.$(n).angle = angle;
        // get number of connections to inner ring
        var numVisibleLinks:int = 0;
        n.visitNodes(function(n2:Node):void
        {
          numVisibleLinks++;
        }, NodeSprite.ALL_LINKS, eq("props.distance", 1));

        // shift positions
        // TODO: this is just a rough approximation, think of better placement algorithm
        n.visitNodes(function(n2:Node):void
        {
          var a1:Number = Math.min(_t.$(n2).angle, _t.$(n).angle);
          var a2:Number = Math.max(_t.$(n2).angle, _t.$(n).angle);
          var angleDiff:Number = a2 - a1;

          if(angleDiff > Math.PI)
          {
            angleDiff -= 2 * Math.PI;
          }
          _t.$(n).angle += angleDiff * .75 / numVisibleLinks;
        }, NodeSprite.ALL_LINKS, eq("props.distance", 1));
      }
      
      var i:int = 0;
    }
  }
}