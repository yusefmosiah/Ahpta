export default ScrollDown = {
    mounted() {
      console.log("ScrollDOwn Hook mounted")
      this.el.scrollTop = this.el.scrollHeight
    },

    updated() {
      if (this.el.dataset.scrolledToTop == "false") {
        this.el.scrollTop = this.el.scrollHeight
      }
    }
  }
