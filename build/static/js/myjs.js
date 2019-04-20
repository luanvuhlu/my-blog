const observer = lozad(); // lazy loads elements with default selector as '.lozad'
observer.observe();

(function ($) {
    "use strict";
    $('.post-editor>p>img').parent().addClass('img-block');
})(jQuery);