// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
    $("#tabs").tabs();

    dragTreeManager.init();

    $("#wrapper p#contextualHelp a").click(Help.click);

    initClickEventsForAssetLinks($("body"));

    init_tag_area();

    initSlugManagement();

    init_sub_nav();

    init_setting_dropdown_ajax();

});


function enable_jwysiwyg_on(selector) {
    $(document).ready(function() {
        try {
            $(selector).wysiwyg({
                controls: {
                    strikeThrough: {
                        visible: false
                    },
                    justifyCenter: {
                        visible: false
                    },
                    justifyFull: {
                        visible: false
                    },
                    justifyCenter: {
                        visible: false
                    },
                    subscript: {
                        visible: false
                    },
                    superscript: {
                        visible: false
                    },
                    redo: {
                        visible: false
                    },
                    undo: {
                        visible: false
                    },
                    html: {
                        visible: true
                    }
                }
            });
            $(selector).wysiwyg("addControl", "asset_selector", {
                groupIndex: 6,
                icon: '/images/library/browse_images_control.gif',
                tooltip: 'Select Image From Library',
                tags: ['library'],
                exec: function() {
                    // $(this) is returning array which have only one object. that is why i am taking first object.
                    Wysiwyg = $(this)[0];
                    var url = "/admin/browser?filter=image"
                    var link = $("<img src='/admin/browser?filter=image' />");
                    var p = $("<p> </p>")
                    $.get(url, null,
                    function(markup) {
                        AssetBrowser.load(p, link, markup, Wysiwyg);
                    });
                },
                callback: function(event, Wysiwyg) {
                    // if we have multiple jWysiwyg on same page. jWysiwyg is calling callback twice which is causing issues. That is why i moved asset selector code
                    // from callback to exec.
                    }
            });
        } catch(e) {
            console.log(e)
        }

    });
}

// This method initialize slug related event on a title text box.
function initSlugManagement() {
    try {
        var pt = $('#page_title');
        var ps = $('#page_slug');

        var regex = /[\!\*'"″′‟‛„‚”“”˝\(\);:.@&=+$,\/?%#\[\]]/gim;

        var pt_function = function()
        {
            if (ps.attr('donotmodify') != 'true') ps.attr('value', pt.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
        };

        pt.bind("keyup", pt_function);
        pt.bind("blur", pt_function);

        ps.bind("blur",
        function()
        {
            ps.attr('value', ps.attr('value').toLowerCase().replace(/\s/gim, '_').replace(regex, ''));
            ps.attr('donotmodify', 'true');
        });
    } catch(e) {
        console.log(e)
    }
}

// input/textarea tags with .tags class will be initlized as
function init_tag_area() {
    try {
        $('.tags').tagarea({
            separator: ','
        });
    } catch(e) {
        console.log(e)
    }
}



// if container element has class "add_to_photoseries" , it returns html of new image
function initClickEventsForAssetLinks(element) {
    element.find(".assetBrowserLink").click(function(e) {
        var p = $(this);
        var link = p.find("a");
        $.get(link.attr("href"), null,
        function(markup) {
            AssetBrowser.load(p, link, markup);
        });
        e.preventDefault();
    });
}


// Common utility functions shared between the different dialogs.
var Dialog = {
    center: function() {
        var offset = $(document).scrollTop();
        for (var i = 0; i < arguments.length; i++) {
            arguments[i].css({
                top: offset + "px"
            });
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
            for (var i = 0; i < this.PADDING_ATTRS.length; i++) {
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
    Wysiwyg: null,
    logo_setting: false,
    filter: null,
    load: function(p, link, markup, Wysiwyg) {
        
        // it is required for asset selector in jWysiwyg
        if (Wysiwyg != undefined) {
            AssetBrowser.Wysiwyg = Wysiwyg;
        }
        // its used for category filtering on assets and collections	
        AssetBrowser.filter = $("#filter_" + $(link).attr("rel"));

        if ($(link).is(".logo_setting")) {
            AssetBrowser.logo_setting = true;
            AssetBrowser.logo_setting_url = $(link).attr("data_url");
        }
        // Set everthing up
        AssetBrowser.showOverlay();
        $("body").append(markup);
        AssetBrowser.browser = $("#assetsDialog");
        try
        {
            AssetBrowser.target = $("#" + $(link).attr("rel"));
            AssetBrowser.imageDisplay = $("#image_" + $(link).attr("rel"));
            AssetBrowser.nameDisplay = $("#show_" + $(link).attr("rel"));
            if (AssetBrowser.nameDisplay !== null) {
                AssetBrowser.nameDisplay = p.find("span");
            }
        } catch(e) {
            AssetBrowser.target = null;
            AssetBrowser.nameDisplay = p.find("span");
        }


        // Grab the various nodes we need
        AssetBrowser.display = AssetBrowser.browser.find("#assetsDisplay");
        AssetBrowser.offsets = AssetBrowser.browser.find("> *:not(#assetsDisplay)");
        AssetBrowser.backControl = AssetBrowser.browser.find("#back a");
        AssetBrowser.backControl.css({
            display: "none"
        });
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
        
        AssetBrowser.browser.find("#ajax_image_upload").click(function(e){
          ajaxFileUpload(link);
          e.preventDefault();
        })
        
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
            AssetBrowser.overlay.css({
                display: "block"
            });
        }
    },
    close: function() {
        AssetBrowser.overlay.css({
            display: "none"
        });
        AssetBrowser.browser.remove();
    },
    handleJSON: function(json) {
        if (json.backURL) {
            AssetBrowser.backURL = json.backURL;
            AssetBrowser.backControl.css({
                display: "block"
            });
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
            if (AssetBrowser.target !== null) {
                AssetBrowser.target.attr("value", id);
                var image = target.find("div").html();

                if (AssetBrowser.Wysiwyg != undefined && AssetBrowser.Wysiwyg !== null) {
                    Wysiwyg = AssetBrowser.Wysiwyg;
                    image_url = target.find(".jwysiwyg_image").val();
                    title = ""
                    description = "";
                    style = "";
                    image = "<img src='" + image_url + "' title='" + title + "' alt='" + description + "'" + style + "/>";
                    Wysiwyg.insertHtml(image);
                }

                AssetBrowser.imageDisplay.html(image);
                AssetBrowser.nameDisplay.html(name);

                // // HACK FOR LOGO SETTINGS
                //                 if (AssetBrowser.logo_setting != undefined && AssetBrowser.logo_setting != null && AssetBrowser.logo_setting == true) {
                //                     url = AssetBrowser.logo_setting_url;
                //                     data_id = $(this).attr("data_id");
                //                     new_value = id;
                // 
                //                     $("#progress_" + data_id).show("fast")
                // 
                //                     $.ajax({
                //                         url: url,
                //                         data: 'gluttonberg_setting[value]=' + new_value,
                //                         type: "PUT",
                //                         success: function(data) {
                //                             $("#progress_" + data_id).hide("fast")
                //                         }
                //                     });
                //                 }
                data_id = $(this).attr("data_id");
                url = AssetBrowser.logo_setting_url;
                auto_save_asset(url , id )
            }

            AssetBrowser.close();
        }
        else if (target.is(".next_page") || target.is(".previous_page") || target.is('a[rel="next"]') || target.is('a[rel="prev"]')) {
            if (target.attr("href") != '') {
                $.getJSON(target.attr("href"), null, AssetBrowser.handleJSON);
            }
        }
        else {
            var url = target.attr("href") + ".json";
            // its collection url then add category filter for filtering assets
            if (target.hasClass("collection")) {
                url += "?filter=" + AssetBrowser.filter.val();
            }
            $.getJSON(url, null, AssetBrowser.handleJSON);
        }
        return false;
    },
    back: function() {
        if (AssetBrowser.backURL) {
            var category = "";
            var show_content = ""
            // if filter exist then apply it on backurl
            if (AssetBrowser.filter !== null) {
                category = "&filter=" + AssetBrowser.filter.val();
            }
            $.get(AssetBrowser.backURL + category + show_content, null, AssetBrowser.updateDisplay);
            AssetBrowser.backURL = null;
            AssetBrowser.backControl.css({
                display: "none"
            });
        }
        return false;
    }

};

function auto_save_asset(url , new_id ){
  // HACK FOR LOGO SETTINGS
  if (AssetBrowser.logo_setting != undefined && AssetBrowser.logo_setting != null && AssetBrowser.logo_setting == true) {
      data_id = data_id;
      new_value = new_id;

      $.ajax({
          url: url,
          data: 'gluttonberg_setting[value]=' + new_value,
          type: "PUT",
          success: function(data) {
          }
      });
  }
}

// Help Browser
// Displays the help in an overlayed box. Intended to be used for contextual
// help initially.
var Help = {
    load: function(url) {
        $.get(url, null,
        function(markup) {
            Help.show(markup)
        });
    },
    show: function(markup) {
        this.buildFrames();
        this.frame.html(markup)
        this.frame.find("a#closeHelp").click(this.close);
        var centerFunction = function() {
            Dialog.center(Help.frame, Help.overlay);
            Dialog.resizeDisplay(Help);
        };
        $(window).resize(centerFunction);
        $(document).scroll(centerFunction);
        centerFunction();
    },
    close: function() {
        Help.display = null;
        Help.offsets = null;
        Help.displayPadding = null;
        Help.frame.hide();
        Help.overlay.hide();
        return false;
    },
    click: function(e) {
        Help.load(this.href);
        return false;
    },
    buildFrames: function() {
        if (!this.overlay) {
            this.overlay = $('<div id="overlay">&nbsp</div>');
            $("body").append(this.overlay);
            this.frame = $('<div id="helpDialog">&nbsp</div>');
            $("body").append(this.frame);
        }
        else {
            this.overlay.show();
            this.frame.show();
        }
    }
};


// Collapsible sub navigation functionality
function init_sub_nav() {
    if ($('#navigation ul a.active').length > 0) {
        $('#navigation ul a.active').parent().parent().parent().addClass('active_parent');
        $('#navigation ul a.active').parent().parent().parent().find('a.nav_trigger').addClass('open');
    } else {
        $('#navigation a.active').parent().addClass('active_parent');
        $('#navigation a.active').parent().find('a.nav_trigger').addClass('open');
    }
    $('#navigation a.nav_trigger').click(function() {
        $(this).next().slideToggle('fast');
        $(this).toggleClass('open');
    });
}

function init_setting_dropdown_ajax()
 {
    $(".setting_dropdown").change(function() {
        url = $(this).attr("rel");
        id = $(this).attr("data_id");
        new_value = $(this).val()

        $("#progress_" + id).show("fast")

        $.ajax({
            url: url,
            data: 'gluttonberg_setting[value]=' + new_value,
            type: "PUT",
            success: function(data) {
                $("#progress_" + id).hide("fast")
            }
        });

    });
    init_home_page_setting_dropdown_ajax();
}

function init_home_page_setting_dropdown_ajax()
 {
    $(".home_page_setting_dropdown").change(function() {
        url = $(this).attr("rel");
        id = "home_page"
        new_value = $(this).val()

        $("#progress_" + id).show("fast")

        $.ajax({
            url: url,
            data: 'home=' + new_value,
            type: "POST",
            success: function(data) {
                $("#progress_" + id).hide("fast")
            }
        });

    })


}


function ajaxFileUpload(link)
{
    //starting setting some animation when the ajax starts and completes
    $("#loading").ajaxStart(function(){
        $(this).show();
    }).ajaxComplete(function(){
        $(this).hide();
    });
    link = $(link);
    
    console.log($("#asset_asset_collection_ids").val())
    asset_name = $('input[name$="asset[name]"]').val();
    var formData = { "asset[name]" : asset_name , "asset[asset_collection_ids]" : $("#asset_asset_collection_ids").val() , "new_collection[new_collection_name]" : $('input[name$="new_collection[new_collection_name]"]').val() }
    
    /*
        prepareing ajax file upload
        url: the url of script file handling the uploaded files
                    fileElementId: the file type of input element id and it will be the index of  $_FILES Array()
        dataType: it support json, xml
        secureuri:use secure protocol
        success: call back function when the ajax complete
        error: callback function when the ajax failed
        
            */
    $.ajaxFileUpload
    (
        {
            url:'/admin/add_asset_using_ajax', 
            secureuri:false,
            fileElementId:'asset_file',
            dataType: 'json',
            data: formData  ,
            //data: {"new_collection[new_collection_name]":"runtime"},
            success: function (data, status)
            {
                if(typeof(data.error) != 'undefined')
                {
                    if(data.error != '')
                    {
                        console.log(data.error);
                    }else
                    {
                        console.log(data.msg);
                    }
                }
                
                
                new_id = data["asset_id"]
                file_path = data["url"]
                
                
                $("#"+ link.attr('rel')).val(new_id);
                //$("#"+ link.attr('rel')).parent().find("img").attr("src" , file_path)
                $("#title_thumb_"+ link.attr('rel')).html("<img src='"+file_path+"' /> " + asset_name );
                
                
                data_id = $(this).attr("data_id");
                url = AssetBrowser.logo_setting_url;
                auto_save_asset(url ,  new_id )
                
                AssetBrowser.close();
                
                
            },
            error: function (data, status, e)
            {
                console.log(data);
                console.log(e);
            }
        }
    )
    
    return false;

}