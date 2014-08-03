$(window).ready(function() {

    var searchInput = $('#search input[type="search"]');
    var helpText = $('#search fieldset p');

    var platformRemoverRegexp = /\b(platform|on\:\w+\s?)+/;

    var allocationSelect = $('#search_results div.allocations');
    var resultsContainer = $('#results_container .results');

    var itemClasses = "col-lg-offset-1 col-sm-offset-1 col-xs-offset-1col-lg-5 col-sm-5 col-xs-10 result"
    var itemClassesOdd = " col-lg-5 col-sm-5 col-xs-10 result"

    searchInput.keyup(function() {
        var input = $(this).val()
        var url = 'http://search.cocoapods.org/api/v1/pods.flat.hash.json?query=' + input

        if (!input.length){
            $('#search form').removeClass("active");
            resultsContainer.empty("div");
            return;
        }

        $.getJSON(encodeURI(url), function(results, textStatus, jqXHR) {
            resultsContainer.empty("div");

            if (results.length) {

                for (var index in results) {
                    var result = results[index]
                    var cd = "http://cocoadocs.org/docsets/"
                    var latestURL =  cd + result["id"]
                    var classes = (index % 2) ? itemClassesOdd : itemClasses;
                    var element = {
                        li : $("<li>", { class: classes }),
                        wrapper : $("<div>"),
                        title : $("<h2>").wrapInner($("<a>", { text: result["id"], href: latestURL })),
                        description : $("<p>", { text: result["summary"] }),
                        linksList : $("<ul>"),
                        latest : $("<li>"),
                        latestLink : $("<a>", { text: "Latest Docs", href: latestURL })
                    };

                    element.latest.append(element.latestLink)
                    element.linksList.append(element.latest)
                    element.wrapper.append(element.title, element.description, element.linksList)
                    element.li.append(element.wrapper)
                    resultsContainer.append(element.li)

                    // trunk is too slow to do this
                    // resultsContainer.mouseenter(function() {
                    //     if ( $(this).hasClass("downloaded") ){
                    //         return;
                    //     }
                    //
                    //     $(this).addClass("downloaded")
                    //     var versions_url = "https://trunk.cocoapods.org/api/v1/pods/" +  result["id"]
                    //     $.getJSON(encodeURI(versions_url), function(results, textStatus, jqXHR) {
                    //         console.log(results)
                    //
                    //         for (var version in results["versions"]) {
                    //             $( this ).find( "ul" ).append("<li><a href='" + cd + "/" + version["name"] + "'>" + version["name"] + "</a></li>");
                    //
                    //         }
                    //     })
                    // })


                    if (index % 2){
                       resultsContainer.append( $("<div>", { class: "clearfix" }) )
                    }
                }
                $('#search form').addClass("active");

            } else {

            }


        });

    });


});
