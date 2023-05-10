window.addEventListener("phx:update", function () {
    initMessageForm();
});

window.addEventListener("phx:submit", function (event) {
    const messageInput = document.getElementById("content");

    if (messageInput) {
        const conversationId = messageInput.form.dataset.conversationId;
        const savedMessageContentKey = `new_message_content_${conversationId}`;
        localStorage.removeItem(savedMessageContentKey);
    }
});

function initMessageForm() {
    const messageInput = document.getElementById("content");

    if (!messageInput) {
        return;
    }

    // Load saved message content from localStorage, using conversation-specific key
    const conversationId = messageInput.form.dataset.conversationId;
    const savedMessageContentKey = `new_message_content_${conversationId}`;
    const savedMessageContent = localStorage.getItem(savedMessageContentKey);
    if (savedMessageContent) {
        messageInput.value = savedMessageContent;
    }

    // Save message content to localStorage on input change, using conversation-specific key
    messageInput.addEventListener("input", function () {
        localStorage.setItem(savedMessageContentKey, messageInput.value);
    });
}

// Call initMessageForm on page load
initMessageForm();
