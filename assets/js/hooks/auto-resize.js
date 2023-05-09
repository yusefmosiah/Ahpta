export default AutoResize = {
    mounted() {
        this.autoresize()
        this.el.addEventListener("input", this.autoresize.bind(this))
    },

    autoresize() {
        this.el.style.height = "auto"
        this.el.style.height = this.el.scrollHeight + "px";
    },
}
