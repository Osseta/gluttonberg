/**
 * editor_plugin_src.js
 *
 * Copyright 2009, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://tinymce.moxiecode.com/license
 * Contributing: http://tinymce.moxiecode.com/contributing
 */

(function(tinymce) {
	tinymce.create('tinymce.plugins.GbAssetsPlugin', {
		init : function(ed, url) {
			// Register commands
			ed.addCommand('gbAsset', function() {
				var url = "/admin/browser?filter=image"
        var link = $("<img src='/admin/browser?filter=image' />");
        var p = $("<p> </p>")
        $.get(url, null,
        function(markup) {
          AssetBrowser.load(p, link, markup, ed);
        });
				
			});

			// Register buttons
			ed.addButton('gb_assets', {title : 'Insert image from asset library', 
			  cmd : 'gbAsset',
			  image : '/gluttonberg/images/library/browse_images_control.gif',
			});
		},

		getInfo : function() {
			return {
				longname : 'Gluttonberg Assets',
				author : 'Freerange Future',
				authorurl : 'http://freerangefuture.com',
				infourl : '',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});

	// Register plugin
	tinymce.PluginManager.add('gb_assets', tinymce.plugins.GbAssetsPlugin);
})(tinymce);