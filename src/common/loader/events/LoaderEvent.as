/**
 * User: Ray Yee
 * Date: 2014/4/6
 * All rights reserved.
 */
package common.loader.events
{
    import common.loader.item.AbstractItem;

    import flash.events.Event;

    public class LoaderEvent extends Event
    {
        public var processingItem:AbstractItem;

        public static const COMPLETE:String = "complete";

        /**
         * @private
         * 该loader被终止以后会触发
         * 不管是加载成功了还是失败
         */
        public static const LOAD_OVER:String = "loadOver";

        public function LoaderEvent( type:String, item:AbstractItem, bubbles:Boolean = false, cancelable:Boolean = false )
        {
            super( type, bubbles, cancelable );
            processingItem = item;
        }
    }
}
