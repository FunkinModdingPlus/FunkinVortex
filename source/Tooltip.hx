package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxSliceSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

enum ArrowDirection
{
	ABOVE;
	BELOW;
	RIGHT;
	LEFT;
}

// thank you Markl <3
class Tooltip extends FlxSliceSprite
{
	var arrow:FlxSprite;

	public var text:FlxText;

	var textPadding:FlxPoint = FlxPoint.get(20, 20);

	var hoverTween:FlxTween;
	var bobUpAndDown = false;

	public var arrowDirection:ArrowDirection;
	public var arrowOffset:Float = 32;

	override public function new(message:String, uiCam:FlxCamera, arrowDirection:ArrowDirection = RIGHT)
	{
		this.cameras = [uiCam];
		this.arrowDirection = arrowDirection;
		text = new FlxText(0, 0, 0, message, 20);
		text.setFormat(null, 18, FlxColor.LIME, "left");
		text.cameras = [uiCam];

		super('assets/images/tooltipbox', FlxRect.get(20, 20, 60, 60), text.textField.textWidth + textPadding.x * 2,
			text.textField.textHeight + textPadding.y * 2);

		arrow = new FlxSprite('assets/images/tooltiparrow.png');
		arrow.cameras = [uiCam];
		if (arrowDirection == RIGHT)
		{
			arrow.angle = -90;
		}

		if (arrowDirection == LEFT)
		{
			arrow.angle = 90;
		}

		if (arrowDirection == ABOVE)
		{
			arrow.angle = 180;
		}
		arrow.scale.x = 0.75;

		// needed otherwise there is tiling behavior
		stretchBottom = true;
		stretchCenter = true;
		stretchLeft = true;
		stretchRight = true;
		stretchTop = true;

		updateTextAndArrow();
	}

	public function setPositionByArrow(newX:Float, newY:Float)
	{
		if (arrowDirection == RIGHT)
		{
			arrow.angle = -90;

			this.x = newX - (this.width + arrow.height - arrowOffset);
			this.y = newY - this.height / 2;
		}

		if (arrowDirection == LEFT)
		{
			arrow.angle = 90;

			this.x = newX + (arrow.height - arrowOffset);
			this.y = newY - this.height / 2;
		}

		if (arrowDirection == BELOW)
		{
			arrow.angle = 0;

			this.x = newX - this.width / 2;
			this.y = newY - (this.height + arrow.height - arrowOffset + 5);
		}

		if (arrowDirection == ABOVE)
		{
			arrow.angle = 180;

			this.x = newX - this.width / 2;
			this.y = newY + arrow.height - arrowOffset + 5;
		}

		updateTextAndArrow();
	}

	public function updateTextAndArrow()
	{
		text.x = this.x + textPadding.x;
		text.y = this.y + textPadding.y;

		if (arrowDirection == RIGHT)
		{
			arrow.x = this.x + this.width - arrowOffset;
			arrow.y = this.y + this.height / 2 - arrow.height / 2;
		}

		if (arrowDirection == LEFT)
		{
			arrow.x = this.x - arrow.width + arrowOffset;
			arrow.y = this.y + this.height / 2 - arrow.height / 2;
		}

		if (arrowDirection == BELOW)
		{
			arrow.x = this.x + this.width / 2 - arrow.width / 2;
			arrow.y = this.y + this.height - arrowOffset + 5;
		}

		if (arrowDirection == ABOVE)
		{
			arrow.x = this.x + this.width / 2 - arrow.width / 2;
			arrow.y = this.y - arrow.height + arrowOffset - 5;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		arrow.update(elapsed);
		text.update(elapsed);

		updateTextAndArrow();

		if (bobUpAndDown && (hoverTween == null || hoverTween.active == false))
		{
			hoverTween = FlxTween.tween(this, {y: this.y - 8}, 3, {type: PINGPONG, ease: FlxEase.quadInOut});
		}

		if (!bobUpAndDown && hoverTween != null && hoverTween.active == true)
		{
			hoverTween.cancel();
		}
	}

	override function draw()
	{
		super.draw();
		arrow.draw();
		text.draw();
	}
}
