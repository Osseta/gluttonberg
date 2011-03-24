$(document).ready(function() {  
	$("#tabs").tabs();   
	initClickEventsForAssetLinks($("body"));
});


// if container element has class "add_to_photoseries" , it returns html of new image
function initClickEventsForAssetLinks( element ){
	element.find(".assetBrowserLink").click(function(e) {   
      var p = $(this);
      var link = p.find("a");
			$.get(link.attr("href"), null, function(markup) {AssetBrowser.load(p, link, markup );});    
			e.preventDefault();
  });
}


// Common utility functions shared between the different dialogs.
var Dialog = {
  center: function() {
    var offset = $(document).scrollTop();
    for (var i=0; i < arguments.length; i++) {
      arguments[i].css({top: offset + "px"});
    };
  },
  PADDING_ATTRS: ["padding-top", "padding-bottom"],
  resizeDisplay: function(object) {
    // Get the display and the offsets if we don't have them
    if (!object.display) object.display = object.frame.find(".display");
    if (!object.offsets) object.offsets = object.frame.find("> *:not(.display)");
    var offsetHeight = 0;
    object.offsets.each(function(i, node) {
      offsetHeight += $(node).outerHeight();
    });
    // Get the padding for the display
    if (!object.displayPadding) {
      object.displayPadding = 0
      for (var i=0; i < this.PADDING_ATTRS.length; i++) {
        object.displayPadding += parseInt(object.display.css(this.PADDING_ATTRS[i]).match(/\d+/)[0]);
      };
    }
    object.display.height(object.frame.innerHeight() - (offsetHeight + object.displayPadding));
  }
};


var AssetBrowser = {
  overlay: null,
  dialog: null,
	imageDisplay: null,
	
	filter: null,
  load: function(p, link, markup ) {
	
		
		AssetBrowser.filter = $("#filter_" + $(link).attr("rel")); // its used for category filtering on assets and collections	
	
    // Set everthing up
    AssetBrowser.showOverlay();
    $("body").append(markup);
    AssetBrowser.browser = $("#assetsDialog");
		try
    {	
			AssetBrowser.target = $("#" + $(link).attr("rel"));			
			AssetBrowser.imageDisplay = $("#image_" + $(link).attr("rel"));
    	AssetBrowser.nameDisplay = $("#show_" + $(link).attr("rel"));	
			if(AssetBrowser.nameDisplay !== null){
					AssetBrowser.nameDisplay = p.find("span");
			}			
		}catch(e){
			AssetBrowser.target = null;  
			AssetBrowser.nameDisplay = p.find("span");  	
		}
		
    
    // Grab the various nodes we need
    AssetBrowser.display = AssetBrowser.browser.find("#assetsDisplay");
    AssetBrowser.offsets = AssetBrowser.browser.find("> *:not(#assetsDisplay)");
    AssetBrowser.backControl = AssetBrowser.browser.find("#back a");
    AssetBrowser.backControl.css({display: "none"});
    // Calculate the offsets
    AssetBrowser.offsetHeight = 0;
    AssetBrowser.offsets.each(function(i, element) {
      AssetBrowser.offsetHeight += $(element).outerHeight();
    });
    // Initialize
    AssetBrowser.resizeDisplay();
    $(window).resize(AssetBrowser.resizeDisplay);
    // Cancel button
    AssetBrowser.browser.find("#cancel").click(AssetBrowser.close);
    // Capture anchor clicks
    AssetBrowser.display.find("a").click(AssetBrowser.click);
    AssetBrowser.backControl.click(AssetBrowser.back);
		

  },
  resizeDisplay: function() {
    var newHeight = AssetBrowser.browser.innerHeight() - AssetBrowser.offsetHeight;
    AssetBrowser.display.height(newHeight);
  },
  showOverlay: function() {
    if (!AssetBrowser.overlay) {
      var height = $('#wrapper').height() + 50;      
      AssetBrowser.overlay = $('<div id="assetsDialogOverlay">&nbsp</div>');      
      $("body").append(AssetBrowser.overlay);
    }
    else {
      AssetBrowser.overlay.css({display: "block"});
    }
  },
  close: function() {
    AssetBrowser.overlay.css({display: "none"});
    AssetBrowser.browser.remove();
  },
  handleJSON: function(json) {
    if (json.backURL) {
      AssetBrowser.backURL = json.backURL;
      AssetBrowser.backControl.css({display: "block"});
    }
    AssetBrowser.updateDisplay(json.markup);
  },
  updateDisplay: function(markup) {
    AssetBrowser.display.html(markup);
    AssetBrowser.display.find("a").click(AssetBrowser.click);
    $('#tabs').tabs();
  },
  click: function() {
    var target = $(this);
    if (target.is(".assetLink")) {
      var id = target.attr("href").match(/\d+$/);
      var name = target.find("h2").html();

      // assets only
			if(AssetBrowser.target !== null){
				AssetBrowser.target.attr("value", id); 
				var image = target.find("div").html();
				AssetBrowser.imageDisplay.html(image);    					      	
				AssetBrowser.nameDisplay.html(name);
			}	
      AssetBrowser.close();
    }
    else if (target.is("#previous") || target.is("#next")) {
      if (target.attr("href") != '') {
        $.getJSON(target.attr("href") + ".json", null, AssetBrowserEx.handleJSON);
      }
    }
    else {
			var url = target.attr("href") + ".json";
			// its collection url then add category filter for filtering assets
			if(target.hasClass("collection")){
				url += "?filter=" + AssetBrowser.filter.val();
			}
      $.getJSON( url , null, AssetBrowser.handleJSON);
    }
    return false;
  },
  back: function() {
    if (AssetBrowser.backURL) {
			var category  = "";
			var show_content = ""
			// if filter exist then apply it on backurl
			if(AssetBrowser.filter !== null){
      	category =  "&filter=" + AssetBrowser.filter.val();
			}
			$.get(AssetBrowser.backURL + category + show_content, null, AssetBrowser.updateDisplay);
      AssetBrowser.backURL = null;
      AssetBrowser.backControl.css({display: "none"});
    }
    return false;
  }

};