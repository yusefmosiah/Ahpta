export default ScrollDown = {
    mounted() {
      console.log("ScrollDOwn Hook mounted")
      this.el.scrollTop = this.el.scrollHeight
    },

    updated() {
    var scrolledToEnd = this.el.scrollHeight - Math.round(this.el.scrollTop) === this.el.clientHeight;

      if (!scrolledToEnd || this.el.dataset.scrolledToTop == "false") {
        this.el.scrollTop = this.el.scrollHeight

      }
    }
  }
