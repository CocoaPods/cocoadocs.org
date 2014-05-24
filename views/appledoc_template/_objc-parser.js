/// http://samvermette.com/313
/// Forked for CocoaDocs: https://github.com/orta/emphasize.js

(function() {

  var Emphasize = { "rules": {} };
  Emphasize.languages = ["highlight-objective-c", "highlight-objc"];
  Emphasize.rules["highlight-objective-c", "highlight-objc"] = [
    [/(#)(.+)(\n)/g, "<em class='em-preprocessor'>$1$2</em>$3"],
    [/(\[|^|&lt;|\(|\s+)([A-Z]{2}[a-zA-Z]{3,})(\s|\*|&gt;|;|,)/g, "$1<em class='em-class'>$2</em>$3"],
    [/(\[|^|\(|\s+)(\w{3,})(\()/g, "$1<em class='em-method'>$2</em>$3"],
    [/(@")([^"]+)(",|"])/g, "<em class='em-string'>$1$2$3</em>"],
    [/(#.*)("|&lt;)(.*)("|&gt;)/g, "$1<em class='em-string'>$2$3$4</em>"],
    [/(\s+)(\w+)(:|])/g, "$1<em class='em-method'>$2</em>$3"],
    [/(\.)([a-zA-Z]{3,})(\s{1}|]|;|\)|,)/g, "$1<em class='em-property'>$2</em>$3"],
    [/(:|\s+)([A-Z]{2}\w{3,})(;|\s|])/g, "$1<em class='em-constant'>$2</em>$3"],
    [/(self|super|nil|@end|@implementation|@synthesize|@property|@interface|@selector|@class)/g, "<em class='em-keyword'>$1</em>"],
    [/(\s+|\(|,)(strong|retain|weak|assign|nonatomic|atomic|readonly|readwrite)(\s+|,|\))/g, "$1<em class='em-keyword'>$2</em>$3"],
    [/(\s+)(for|while|do|if|else|break|in)(\s+|\()/g, "$1<em class='em-keyword'>$2</em>$3"],
    [/(\s+|:)(YES|NO|return|break|continue|)(\s+|;)/g, "$1<em class='em-keyword'>$2</em>$3"],
    [/(\s+|\()(void|BOOL)(\s+|\))/g, "$1<em class='em-keyword'>$2</em>$3"],
    [/(?:\/\*(?:[\s\S]*?)\*\/)|(?:([\s;])+\/\/(?:.*)$)/gm, "<em class='em-comment'>$1$2$3</em>"],
    [/(\s+|:|,)([0-9])(\s+|:|,|;)/g, "$1<em class='em-number'>$2</em>$3"]
  ];

  Emphasize.query = ".highlight." + Emphasize.languages.join(" , .highlight.");
  Emphasize.regex = new RegExp("(\\s|^)(" + Emphasize.languages.join("|") + ")(\\s|$)", "i");

  var blocks = document.querySelectorAll(Emphasize.query);
  for(var i = 0; i < blocks.length; i++) {
      var block = blocks[i],
          text = (block.textContent || block.innerText).replace(/</g, "&lt;").replace(/>/g, "&gt;"),
          language;

      if(language = block.className.match(Emphasize.regex)) {
        var rules = Emphasize.rules[language[2]];
        for(var r = 0; r < rules.length; r++) {
          var rule = rules[r];
          text = text.replace(rule[0], rule[1]);
        }
      }

      block.innerHTML = "<pre>" + text + "</pre>";
  };

})();
