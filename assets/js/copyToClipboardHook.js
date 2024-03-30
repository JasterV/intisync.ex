const CopyToClipboard = () => {
  return {
    mounted() {
      const initialInnerHTML = this.el.innerHTML;
      const { textToCopy } = this.el.dataset;

      this.el.addEventListener("click", () => {
        navigator.clipboard.writeText(textToCopy);

        this.el.innerHTML = "Copied!";

        setTimeout(() => {
          this.el.innerHTML = initialInnerHTML;
        }, 2000);
      });
    },
  };
};

export default CopyToClipboard;
