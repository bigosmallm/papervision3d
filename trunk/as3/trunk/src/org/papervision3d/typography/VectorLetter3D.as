package org.papervision3d.typography {	import org.papervision3d.core.geom.renderables.Vertex3D;	import org.papervision3d.materials.special.Letter3DMaterial;	import org.papervision3d.objects.special.VectorShape3D;			/**	 * @author Mark Barcinski	 */	public class VectorLetter3D extends VectorShape3D implements Letter3D {		private var _width:Number;		private var _height:Number;		private var _char : String;		private var _font:Font3D;				public function VectorLetter3D(char:String , material : Letter3DMaterial , font :Font3D) {			this._char = char;			this._font = font;						super(material , null);			getLetterFromFont();						//center vertices & flip vertically			for each(var v:Vertex3D in geometry.vertices)			{				// center				v.x -= _width/2;				v.y -= _height/2;								// flip 				v.y *= -1;			}		}				protected function getLetterFromFont():void		{			_width = _font.widths[_char];			_height = _font.height;						createVertices(_font.motifs[_char]);		}		protected function createVertices(motif:Array):void		{			for (var i:int=0; i<motif.length; i++) {				switch (motif[i][0]) 				{					case "M":						graphics.moveTo(motif[i][1][0], motif[i][1][1]);						break;					case "L":						graphics.lineTo(motif[i][1][0], motif[i][1][1]);						break;					case "C":						graphics.curveTo(motif[i][1][0], motif[i][1][1], motif[i][1][2], motif[i][1][3]);						break;				}			}		}				public function get width() : Number {			return _width;		}				public function set width(value : Number) : void {			_width = value;		}				public function get height() : Number {			return _height;		}				public function set height(height : Number) : void {			_height = height;		}				public function get char() : String {			return _char;		}				public function set char(value : String) : void {			_char = value;		}				public function get font() : Font3D {			return _font;		}				public function set font(value : Font3D) : void {			_font = value;		}	}}