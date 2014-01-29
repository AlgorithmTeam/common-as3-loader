/**
 * User: Ray Yee
 * Date: 14-1-29
 * All rights reserved.
 */
package common.loader.item
{
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLRequest;

    public class SWFItem extends AbstractItem
    {
        private var _loader:Loader;

        public function SWFItem( url:String, prop:Object )
        {
            super( url, prop );
        }

        override public function load():void
        {
            super.load();
            _loader = new Loader();
            _loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onCompleteHandler );
            _loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onProgressHandler );
            _loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onIOErrorHandler );
            _loader.load( new URLRequest( _sUrl ) );
        }

        override protected function onCompleteHandler( e:Event ):void
        {
            _content = _loader.contentLoaderInfo;
            super.onCompleteHandler( e );
        }

        public function getDefinitionByName( name:String ):Class
        {
            var loadInfo:LoaderInfo = _content;
            return loadInfo.applicationDomain.getDefinition( name ) as Class;
        }
    }
}