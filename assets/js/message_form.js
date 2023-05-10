window.addEventListener("phx:update", function () {
    initMessageForm();
  });

  function initMessageForm() {
    const messageInput = document.getElementById("content");

    if (!messageInput) {
      return;
    }

    // Load saved message content from localStorage
    const savedMessageContent = localStorage.getItem("new_message_content");
    if (savedMessageContent) {
      messageInput.value = savedMessageContent;
    }

    // Save message content to localStorage on input change
    messageInput.addEventListener("input", function () {
      localStorage.setItem("new_message_content", messageInput.value);
    });
  }

  // Call initMessageForm on page load
  initMessageForm();
