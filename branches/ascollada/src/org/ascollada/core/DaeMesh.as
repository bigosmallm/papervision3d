/*
 * Copyright 2007 (c) Tim Knip, ascollada.org.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
 
package org.ascollada.core {
	
	import org.ascollada.ASCollada;
	import org.ascollada.utils.Logger;
	
	/**
	 * 
	 */
	public class DaeMesh extends DaeEntity {
		
		/** vertices */
		public var vertices:Array;
		
		/** faces */
		public var faces:Array;
		
		/** normals */
		public var normals:Array;
		
		/** texcoords */
		public var texcoords:Array;
		
		/** materials */
		public var materials:Array;
		
		/**
		 * 
		 * @param	node
		 */
		public function DaeMesh( node:XML = null ) {
			super( node )
		}
		
		/**
		 * 
		 * @return
		 */
		override public function read( node:XML ):void {
			if( node.localName() != ASCollada.DAE_MESH_ELEMENT && node.localName() != ASCollada.DAE_CONVEX_MESH_ELEMENT )
				throw new Error( "expected a '" + ASCollada.DAE_MESH_ELEMENT + " or a '" + ASCollada.DAE_CONVEX_MESH_ELEMENT + "' element" );
				
			super.read( node );
		
			this.vertices = new Array();
			this.faces = new Array();
			this.normals = new Array();
			this.texcoords = new Array();
			this.materials = new Array();
			
			var sourceList:XMLList = getNodeList( node, ASCollada.DAE_SOURCE_ELEMENT );
			var sourceNode:XML;
			var source:DaeSource;
			var sources:Object = new Object();
			
			var verticesNode:XML = getNode(node, ASCollada.DAE_VERTICES_ELEMENT);
			var verticesId:String = verticesNode.attribute(ASCollada.DAE_ID_ATTRIBUTE).toString();
			
			var inputList:XMLList = getNodeList( verticesNode, ASCollada.DAE_INPUT_ELEMENT );
			var inputNode:XML;
			
			for each( sourceNode in sourceList ) {
				source = new DaeSource( sourceNode );
				sources[ source.id ] = source.values;
			}
			
			for each( inputNode in inputList ) {
				var input:DaeInput = new DaeInput( inputNode );
				if( input.semantic == "POSITION" ) {
					this.vertices = sources[ input.source ];
					sources[ verticesId ] = sources[ input.source ];
				}
			}	
					
			var triangles:XMLList = getNodeList( node, ASCollada.DAE_TRIANGLES_ELEMENT );
			if( triangles.length() ) {
				for each( var trianglesNode:XML in triangles )
					parseTriangles( trianglesNode, sources );
				return;
			}
			
			var polylists:XMLList = getNodeList( node, ASCollada.DAE_POLYLIST_ELEMENT );
			if( polylists.length() ) {
				for each( var polylistNode:XML in polylists )
					parsePolyList( polylistNode, sources );
				return;
			}
		}
		
		/**
		 * 
		 * @param	node
		 * @param	sources
		 * @return
		 */
		private function parsePolyList( node:XML, sources:Object ):void {
			
			var inputList:XMLList = getNodeList( node, ASCollada.DAE_INPUT_ELEMENT );
			var inputs:Array = new Array();
			var input:DaeInput;
			
			for each( var inputNode:XML in inputList ) {
				input = new DaeInput( inputNode );
				inputs.push( input );
			}
			
			var p:Array = getInts( getNode(node, ASCollada.DAE_POLYGON_ELEMENT) );
			var pidx:uint = 0;
						
			var vcount:Array = getInts(getNode(node, ASCollada.DAE_VERTEXCOUNT_ELEMENT));
			
			for( var i:uint = 0; i < vcount.length; i++ ) {
				
				var tri:Array = new Array();
				var nor:Array = new Array();
				var tex:Array = new Array();
			
				var v:Number = vcount[i];
				
				for( var j:uint = 0; j < v; j++ ) {
					for( var k:uint = 0; k < inputs.length; k++ ) {
						input = inputs[k];
						
						var values:Array = sources[ input.source ];
						
						switch( input.semantic ) {
							case "VERTEX":
								tri.push( p[pidx + input.offset] );
								break;
							case "NORMAL":
								nor.push( values[p[pidx + input.offset]] );
								break;
							case "TEXCOORD":
								tex.push( values[p[pidx + input.offset]] );
								break;
							default:
								break;
						}
					}
					
					pidx += inputs.length;
				}
				
				this.faces.push( tri );
				this.texcoords.push( tex );
				this.normals.push(nor);
				this.materials.push( node.@material ); // C4
			}
			
			triangulate();
		}
				
		/**
		 * 
		 * @param	node
		 * @param	sources
		 * @return
		 */
		private function parseTriangles( node:XML, sources:Object ):void {
			var inputList:XMLList = getNodeList( node, ASCollada.DAE_INPUT_ELEMENT );
			var inputs:Array = new Array();
			var input:DaeInput;
			var p:Array = getInts( getNode(node, ASCollada.DAE_POLYGON_ELEMENT) );
			var tri:Array = new Array();
			var nor:Array = new Array();
			var tex:Array = new Array();
			
			for each( var inputNode:XML in inputList ) {
				input = new DaeInput( inputNode );
				inputs.push( input );
			}
			
			for( var i:int = 0; i < p.length; i += inputs.length ) {
				for each( input in inputs ) {
					var idx:int = p[i + input.offset];
					var values:Array = sources[ input.source ];
					
					switch( input.semantic ) {
						case "VERTEX":
							tri.push( idx );
							if( tri.length == 3 ) {
								this.faces.push( tri );
								tri = new Array();
								this.materials.push( node.@material ); // C4
							}
							
							break;
						
						case "NORMAL":
							nor.push( values[idx] )
							if( nor.length == 3 ) {
								this.normals.push( nor );
								nor = new Array();
							}
							break;
							
						case "TEXCOORD":
							tex.push( values[idx] );
							if( tex.length == 3 ) {
								this.texcoords.push( tex );
								tex = new Array();
							}
							break;
							
						default:
							break;
					}
				}
			}
			/*
			Logger.trace( " => verts #" + this.vertices.length + " => " + this.vertices );
			Logger.trace( " => faces #" + this.faces.length + " => " + this.faces.join("@") );
			Logger.trace( " => normals #" + this.normals.length + " => " + this.normals.join("@") );
			Logger.trace( " => texcoords #" + this.texcoords.length + " => " + this.texcoords.join("@") );
			*/
		}
		
		/**
		 * triangulates the mesh's faces, texcoords and normals.
		 * 
		 * @return
		 */
		private function triangulate():void {
			
			var tris:Array = new Array();
			var uvs:Array = new Array();
			var norms:Array = new Array();
			var mats:Array = new Array();
			
			for( var i:uint = 0; i < this.faces.length; i++ ) {
				
				var face:Array = this.faces[i];
				var tex:Array = this.texcoords[i];
				var nor:Array = this.normals[i];
				var mat:String = this.materials[i];
				
				if( face.length > 3 ) {
					
					var idx0:int = Number(face.shift());
					var idx1:int = Number(face.shift());
					var idx2:int = Number(face.shift());
					
					var t0:Array = tex.shift() as Array;
					var t1:Array = tex.shift() as Array;
					var t2:Array = tex.shift() as Array;
					
					var n0:Array = nor.shift() as Array;
					var n1:Array = nor.shift() as Array;
					var n2:Array = nor.shift() as Array;
					
					if( n0 && n1 && n2 )
						norms.push([n0, n1, n2]);
					else
						norms.push([]);
						
					tris.push([idx0, idx1, idx2]);
					uvs.push([t0, t1, t2]);
					mats.push(mat);
					
					while( face.length ) {
						var idx3:int = Number(face.shift());
						var t3:Array = tex.shift() as Array;
						var n3:Array = nor.shift() as Array;
						
						tris.push([idx0, idx2, idx3]);
						uvs.push([t0, t2, t3]);
						if( n3 )
							norms.push([n0, n2, n3]);
						else
							norms.push([]);
						mats.push(mat);
					}
				} else {
					tris.push(face);
					uvs.push(tex);
					norms.push(nor);
					mats.push(mat);
				}
			}

			this.faces = tris;
			this.texcoords = uvs;
			this.normals = norms;
			this.materials = mats;
		}
	}
}