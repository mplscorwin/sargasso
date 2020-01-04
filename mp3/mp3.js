/// mp3.js -- web behaviours for sargasso mp3 editor -*- mode:js2 -*-
;$( document ).ready(function() {
    var cache = { tracks: [], markers: {} };

    function hexToRgbA(hex){
	console.log( hex );
	var c;
	if(/^#([A-Fa-f0-9]{3}){1,2}$/.test(hex)){
            c= hex.substring(1).split('');
            if(c.length== 3){
		c= [c[0], c[0], c[1], c[1], c[2], c[2]];
            }
            c= '0x'+c.join('');
            return 'rgba('+[(c>>16)&255, (c>>8)&255, c&255].join(',')+',.2)';
	}
	throw new Error('Bad Hex');
    }

    var lastClickedRegion;

    //var path;// = '/corwin-phone-audio/sargasso-july-2018.mp3';
    var wavesurfer = WaveSurfer.create({
	container: '#playerFrameDiv',
	//waveColor: '#A8DBA8',
	//progressColor: '#3B8686',
	waveColor: 'violet',
	progressColor: 'purple',
	backend: 'MediaElement',
	splitChannels: true,
	//scrollParent: true,

	plugins: [
	    WaveSurfer.regions.create({
			regions: [ ],
			dragSelection: {
		    	slop: 5
			},
			enableDragSelection: { drag: true, resize: true },
			drag: true,
			resize: true,
	    }),
	    WaveSurfer.timeline.create({
			container: '#playerTimelineDiv',
			primaryColor: '#F00',
			secondaryColor: '#F00',
			primaryFontColor: '#0F0',
			secondaryFontColor: '#0F0'
        })
	],
    });
    wavesurfer.on('error', function(e) {
		console.warn(e);
    });

    /* Progress bar */
    (function() {
        var progressDiv = document.querySelector('#progress-bar');
        var progressBar = progressDiv.querySelector('.progress-bar');

        var showProgress = function(percent) {
            progressDiv.style.display = 'block';
            progressBar.style.width = percent + '%';
        };

        var hideProgress = function() {
            progressDiv.style.display = 'none';
        };

        wavesurfer.on('loading', showProgress);
        wavesurfer.on('ready', hideProgress);
        wavesurfer.on('destroy', hideProgress);
        wavesurfer.on('error', hideProgress);
    })();
    $('#slider').change(function () {
		var val = parseFloat($(this).val());
		//console.log(val);
		wavesurfer.zoom(val);
    });
    // color picker change event
    $("#showPallete").on('change',function(target) {
	lastClickedRegion.data.color = $( this ).val();
	lastClickedRegion.update({color: hexToRgbA( lastClickedRegion.data.color )});
    });

    // executed when a track is selected
    function FindTrackInCache(path) {
	for(var i =0;i<cache.tracks.length;++i) {
	    if( cache.tracks[ i ].path == path )
		return cache.tracks[ i];
	}
	return undefined;
    }

    // region selection
    function RegionSelectedHandler(region) {
	lastClickedRegion = region;
	console.log(region);
	$('#markerTitle').val( region.data.title);
	$('#markerNotes').val( region.data.notes);
	$('#showPallete').val( region.data.color);
	var start = ParseDuration( region.start);
	$('#markerStart').val( start.number);
	$('#markerStartInt').val( start.text);
	var end = ParseDuration( region.end);
	$('#markerEnd').val( end.number);
	$('#markerEnd,#markerEndInt').val( end.text);
    }
    wavesurfer.on('region-click', RegionSelectedHandler);
    $('#loopMarker').click(function() {	lastClickedRegion.playLoop();   });
    wavesurfer.on('region-created',function(region) {
	if(! (region.data && region.data.title && region.data.title.length > 0)) {
	    // freshly drawn region
	    region.color = '#00f';//'hsla(200, 50%, 70%, 0.4)';
	    lastClickedRegion = region;
	    $("#markerTitle").focus();
	}
    });

    function SecondsToHMS(seconds) { //https://stackoverflow.com/questions/1322732/convert-seconds-to-hh-mm-ss-with-javascript
	return new Date(seconds * 1000).toISOString().substr(11, 8); }
    function HMSToSeconds(str) { //https://stackoverflow.com/questions/9640266/convert-hhmmss-string-to-seconds-only-in-javascript
	var p = str.split(':'),
            s = 0, m = 1;
	while (p.length > 0) {
            s += m * parseInt(p.pop(), 10);
            m *= 60;
	}
	return s; }
    function ParseDuration(newValue) {
	var intValue;
	var textValue;
	if(newValue.toString().indexOf(':')==-1) {
	    intValue = parseFloat( newValue );
	    textValue = SecondsToHMS( intValue);
	} else {
	    textValue = newValue;
	    intValue = HMSToSeconds( parseFloat( textValue));
	}
	return {number:intValue,text:textValue};
    }
    
    wavesurfer.on('loading', function(pct) {
	$('#playheadPosition').text( pct == 100 ? '..read..' : pct.toString() + "%");
    });
    wavesurfer.on('audioprocess',function(o) {
	var text = SecondsToHMS( parseInt( wavesurfer.getCurrentTime( )));
	$('#playheadPosition').text( text);
    });

    function OnMarkerStartChange(newValue) {
	var val = ParseDuration(newValue);
	$("#markerStart").val(val.number);
	$("#markerStartInt").val(val.text);
	lastClickedRegion.update({start:val.number});
    }
    function OnMarkerEndChange(newValue) {
	var val = ParseDuration(newValue);
	$("#markerEnd").val(val.text);
	$("#markerEndInt").val(val.number);
	lastClickedRegion.update({end:val.number});
    }

    $('#markerStart').on('input',function(){ OnMarkerStartChange( $(this).val());});
    $('#markerEnd').on('input',function(){ OnMarkerEndChange( $(this).val())});
    $('#markerStartInt').on('input',function(){ OnMarkerStartChange( $(this).val());});
    $('#markerEndInt').on('input',function(){ OnMarkerEndChange( $(this).val());});

    wavesurfer.on('region-updated',function(region) {
	var start = ParseDuration(region.start);
	$("#markerStart").val(start.number);
	$("#markerStartInt").val(start.text);

	var end = ParseDuration(region.end);
	$("#markerEnd").val(end.number);
	$("#markerEndInt").val(end.text);
    });

    $("#markerTitle").change(function() { lastClickedRegion.data.title = $(this).val(); });
    $("#markerNotes").change(function() { lastClickedRegion.data.notes = $(this).val(); });

    function PathSelectedHandler(path) {
	ShowEditor();
	$("#editorPath").html("<a id=\"directLink\" href=\"" + path + "\">" + path + "</a>");
	// start loading first thing
	wavesurfer.load( path);
	var track = FindTrackInCache(path);
	console.log(track);
	// populate track meta-data editor
	$('#artist').val( track.artist );
	$('#album').val( track.album );
	$('#title').val( track.title );
	$('#dttm').val( track.dttm );

	// set valid values for region editor size and position sliders
	$('#markerStart,#markerEnd').prop('max',track.secs);

	// fetch markers
	$.ajax({dataType:"json",url:'/mp3/api/get-markers.pl',data:{path:path},
		success:function(data) {
		    //console.log( data );
		    var regions = cache.markers[ path ] = data;
		    //console.log(regions); 
		    for(var i=0; i<regions.length; ++i) {
			var d = regions[i];
			var r = { start:d.start, end:d.end, color:hexToRgbA( d.color), data:d };
			wavesurfer.addRegion( r);
		    }
		},
		error:function(e,eStr) {
		    console.log(e,eStr);
		}});

	wavesurfer.on('ready', function(e) {
	    $('#playheadPosition').text( "0");

	    // transport controls
	    $('#rewind').click(function() { wavesurfer.seekTo( 0);   });
	    $('#back').click(function() { wavesurfer.skipBackward();   });
	    //$('#play').click(function() { wavesurfer.play();   });
	    //$('#pause').click(function() { wavesurfer.pause();   });
	    $('#play').click(function() { wavesurfer.playPause();   });
	    //$('#center').click(function() { wavesurfer.seekAndCenterpause();   });
	    $('#forward').click(function() { wavesurfer.skipForward();   });
	    $('#gotoend').click(function() { wavesurfer.seekTo( 1);   });
	});
	//SerializeRegions();
    }
    //PathSelectedHandler( path);

    // collect all regions into JSON for persistance API
    function SerializeRegions() {
	var json = [];
	var list = wavesurfer.regions.list;
	//console.log( list);
	Object.keys(list).forEach(id => {
            var region = list[id];
	    //console.log( region);
	    var o = {
		start:region.start,
		end:region.end,
		color:region.data.color,
		title:region.data.title,
		notes:region.data.notes
	    };
	    json.push( o );
        });
	//console.log(JSON.stringify(json));
	return JSON.stringify(json);
    }
    function RemoveRegion() {
	lastClickedRegion.remove();
    }
    $("#removeMarker").click(RemoveRegion);

    function OnExportMarker() {
	var url = '/mp3/api/export-markers.pl';
	var data = {path:$("#directLink").text()};
	$.ajax({url:url,
		data:data,
		success:function(data) {
		    console.log(data?"markersExported":"markers not exported");
		    LoadTracks();; // reload the track list
		},
		error:function(e,eStr) {
		    console.log("Marker Save Failed",eStr,e);
		}
	       });
    }
    $('#exportMarker').on('click', function() {
	OnExportMarker();
    });

    function OnSaveMarker() {
	console.log('save marker handler');
	var json = SerializeRegions();
	var url = '/mp3/api/put-markers.pl';
	var data = {path:$("#directLink").text(),markers:json};
	console.log(url,data,json);
	$.ajax({url:url,
		data:data,
		success:function(data) {
		    console.log('succecss handler');
		    console.log("markersSaved");
		},
		error:function(e,eStr) {
		    console.log('failure handler');
		    console.log("Marker Save Failed",eStr,e);
		}
	       });
    }
    $('#saveMarker').on('click', function() {
	console.log('click handler');
	OnSaveMarker();
    });

    function OnSaveTags() {
	var url = '/mp3/api/put-tags.pl';
	var data = {path:$("#editorPath").text()};
	["artist","album","title"].forEach(function(elem,ix) {
	    data[ elem ] = $("#" + elem).val();
	});
	console.log(url,data);
	$.ajax({url:url,
		data:data,
		success:function(data) { console.log("tagsSaved");},
		error:function(e,eStr) { console.log("Tag Save Failed",eStr,e);	}
	       });
    }
    $('#saveTags').on('click', function() { OnSaveTags(); });

    var $idown;
    function downloadURL(url) {
	if ($idown) {
	    $idown.attr('src',url);
	} else {
	    $idown = $('<iframe>', { id:'idown', src:url }).hide().appendTo('body');
	}
    }

    function OnTrackData(data) {
	cache.tracks = data;
	var $list = $("#listTableBody");
	$list.empty();
	for(var i=0; i<data.length; ++i) {
	    var d = data[i];
	    var path = d.path;
	    //console.log(d);
	    var html =( "<tr><td class=\"direct-list\">"  + "&oplus;" +
			"</td><td>"  + d.artist +
			"</td><td>" + d.album  +
			"</td><td>" + d.title  +
			"</td><td>" + d.dttm  +
			"</td><td>" + d.ctime  +
			"</td><td>" + d.mtime  +
			"</td><td>" + d.atime  +
			"</td></tr>" );
	    var $html = $( html );
	    $html.hover(function(){ $("#editorPath").html($(this).data('path')); },
			function(){ /*$("#editorPath").html("");*/   });
	    $html.data( d );
	    $html.find(".direct-list").off("click").on("click", function(){ downloadURL($(this).data("path"));});
	    $html.click(function(){
		//console.log({msg:"track selected",i:i,d:d,data_i:data[i],path:path});
		//PathSelectedHandler(path);
		PathSelectedHandler($(this).data('path'));
	    });
	    //$html.find(".direct-list").off("click").click(function(){window.location = $(this).data('path');  });
	    //console.log( $html );
	    $list.append( $html );
	}
    }

    function LoadTracks() {
	$.ajax({url:"/mp3/api/get.pl",
		success:OnTrackData,
		error:function(err,eStr){ console.log("load tracks failed",eStr,err);}});}
    LoadTracks();
    ShowList();

    function ShowEditor() {
	$("#listFrameDiv").hide();
	$("#outterFrameDiv").show();
    }
    function ShowList() {
	$("#listFrameDiv").show();
	$("#outterFrameDiv").hide();
    }
    $("#closeTrack").click(function(){
	$("#editorPath").html("");
	ShowList();
    });

    // sorting
    $('th').click(function(){
	var table = $(this).parents('table').eq(0);
	var rows = table.find('tr:gt(0)').toArray().sort(comparer($(this).index()));
	this.asc = !this.asc;
	if (!this.asc) {
	    rows = rows.reverse();
	}
	for (var i = 0; i < rows.length; i++) {
	    table.append(rows[i]);
	}
    });
    function comparer(index) {
	return function(a, b) {
            var valA = getCellValue(a, index),
		valB = getCellValue(b, index);
            return $.isNumeric(valA) && $.isNumeric(valB)
		? valA - valB
		: valA.toString().localeCompare(valB);
	};
    }
    function getCellValue(row, index){ return $(row).children('td').eq(index).text(); }
}); // end wrap
