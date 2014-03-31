/**
 * User: Ray Yee
 * Date: 14-4-1
 * All rights reserved.
 */
package common.loader.item
{
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.errors.EOFError;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLRequest;
    import flash.net.URLStream;
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    public class AVM1MovieItem extends AbstractItem
    {
        private var _loader:Loader;
        private var _stream:URLStream;

        public function AVM1MovieItem( url:String, prop:Object )
        {
            super( url, prop );
        }

        override public function load():void
        {
            super.load();
            _loader = new Loader();
            _loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onCompleteHandler );
            _stream = new URLStream();
            _stream.addEventListener( Event.COMPLETE, onStreamCompleteHandler );
            _stream.addEventListener( ProgressEvent.PROGRESS, onProgressHandler );
            _stream.addEventListener( IOErrorEvent.IO_ERROR, onIOErrorHandler );
            _stream.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler );
            _stream.load( new URLRequest( _sUrl ) );
        }

        public function getMovieClip():MovieClip
        {
            return _loader.content as MovieClip;
        }

        public function getSWFDisplayContent():DisplayObject
        {
            return _loader.content;
        }

        private function onStreamCompleteHandler( e:Event ):void
        {
            var inputBytes:ByteArray = new ByteArray();
            _stream.readBytes( inputBytes );
            _stream.close();
            inputBytes.endian = Endian.LITTLE_ENDIAN;

            if ( isCompressed( inputBytes ) )
            {
                uncompress( inputBytes );
            }

            var version:uint = uint( inputBytes[3] );

            if ( version < 9 )
            {
                updateVersion( inputBytes, 9 );
            }
            if ( version > 7 )
            {
                flagSWF9Bit( inputBytes );
            }
            else
            {
                insertFileAttributesTag( inputBytes );
            }

            _loader.loadBytes( inputBytes );
        }

        private function isCompressed( bytes:ByteArray ):Boolean
        {
            return bytes[0] == 0x43;
        }

        private function uncompress( bytes:ByteArray ):void
        {
            var cBytes:ByteArray = new ByteArray();
            cBytes.writeBytes( bytes, 8 );
            bytes.length = 8;
            bytes.position = 8;
            cBytes.uncompress();
            bytes.writeBytes( cBytes );
            bytes[0] = 0x46;
            cBytes.length = 0;
        }

        private function getBodyPosition( bytes:ByteArray ):uint
        {
            var result:uint = 0;

            result += 3; // FWS/CWS
            result += 1; // version(byte)
            result += 4; // length(32bit-uint)

            var rectNBits:uint = bytes[result] >>> 3;
            result += (5 + rectNBits * 4) / 8; // stage(rect)

            result += 2;

            result += 1; // frameRate(byte)
            result += 2; // totalFrames(16bit-uint)

            return result;
        }

        private function findFileAttributesPosition( offset:uint, bytes:ByteArray ):uint
        {
            bytes.position = offset;

            try
            {
                for ( ; ; )
                {
                    var byte:uint = bytes.readShort();
                    var tag:uint = byte >>> 6;
                    if ( tag == 69 )
                    {
                        return bytes.position - 2;
                    }
                    var length:uint = byte & 0x3f;
                    if ( length == 0x3f )
                    {
                        length = bytes.readInt();
                    }
                    bytes.position += length;
                }
            }
            catch ( e:EOFError )
            {
            }

            return NaN;
        }

        private function flagSWF9Bit( bytes:ByteArray ):void
        {
            var pos:uint = findFileAttributesPosition( getBodyPosition( bytes ), bytes );
            if ( !isNaN( pos ) )
            {
                bytes[pos + 2] |= 0x08;
            }
        }

        private function insertFileAttributesTag( bytes:ByteArray ):void
        {
            var pos:uint = getBodyPosition( bytes );
            var afterBytes:ByteArray = new ByteArray();
            afterBytes.writeBytes( bytes, pos );
            bytes.length = pos;
            bytes.position = pos;
            bytes.writeByte( 0x44 );
            bytes.writeByte( 0x11 );
            bytes.writeByte( 0x08 );
            bytes.writeByte( 0x00 );
            bytes.writeByte( 0x00 );
            bytes.writeByte( 0x00 );
            bytes.writeBytes( afterBytes );
            afterBytes.length = 0;
        }

        private function updateVersion( bytes:ByteArray, version:uint ):void
        {
            bytes[3] = version;
        }
    }
}