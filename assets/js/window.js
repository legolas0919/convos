(function() {
  window.hasFocus = true;
  window.isMobile = navigator.userAgent.match(/Android|iPad|iPhone|iPod|webOS|Windows Phone/i) || location.href.match(/\bisMobile=1\b/)
  window.isTouchDevice = !!("ontouchstart" in window);
  window.nextTick = function(cb) { setTimeout(cb, 1); };

  Date.fromAPI = function(t) {
    if (!t) return new Date();
    if (!t.match(/Z$/)) t += "Z"
    return new Date(t);
  };

  Date.prototype.epoch = function() {
    return this.getTime() / 1000;
  };

  Date.prototype.getAbbrMonth = function() {
    switch(this.getMonth()) {
      case 0: return 'Jan';
      case 1: return 'Feb';
      case 2: return 'March';
      case 3: return 'Apr';
      case 4: return 'May';
      case 5: return 'Jun';
      case 6: return 'July';
      case 7: return 'Aug';
      case 8: return 'Sept';
      case 9: return 'Oct';
      case 10: return 'Nov';
      case 11: return 'Dec';
    }
  };

  Date.prototype.getHM = function() {
    return [this.getHours(), this.getMinutes()].map(function(v) { return v < 10 ? '0' + v : v; }).join(':');
  };

  Element.prototype.focusOnDesktop = function() {
    if (!isMobile) window.nextTick(function() { this.focus(); }.bind(this));
  };

  Object.$values = function(obj) {
    return Object.keys(obj).sort().map(function(k) { return obj[k]; });
  };

  RegExp.escape = function(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  };

  window.onpageshow = window.onpagehide = window.onfocus = window.onblur = function(e) {
    window.hasFocus = e.type.match(/blur|hide/) ? false : true;
    if (DEBUG.debug) console.log("[focusChanged]", e.type, window.hasFocus);
  };

  $.fn.injectSVG = function() {
    return this.each(function() {
      var $img = $(this);
      $.get($img.attr("src"), function(data) {
        $img.replaceWith($(data).find("svg").removeAttr('xmlns:a').attr("class", $img.attr("class")));
      });
    });
  };
})();
