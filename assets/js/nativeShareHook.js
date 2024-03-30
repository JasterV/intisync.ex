const NativeShare = () => {
  return {
    mounted() {
      this.el.addEventListener("click", async () => {
        // Check if sharing is supported
        if (!navigator.canShare) {
          this.pushEvent("url_share_error", {
            error: "Unfortunately, sharing is not supported",
          });
          return;
        }

        try {
          await navigator.share({
            title: this.el.dataset.title,
            text: this.el.dataset.text,
            url: this.el.dataset.url,
          });
          this.pushEvent("url_shared", {});
        } catch (error) {
          this.pushEvent("url_share_error", { error: error.message });
        }
      });
    },
  };
};
export default NativeShare;
