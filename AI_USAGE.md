# AI usage: dsc26-flt-w04

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

ChatGPT: To understand the task requirements, discuss implementation approaches, generate code suggestions, and review edge cases.

Visual Studio Code: To edit and organize the project files.

Flutter and Dart tools: To analyze the code and run tests.

Git and GitHub: To manage version control and the project repository.

## 2. My best prompts

Help me implement a reliable offline-first Outbox in Dart with persistent local storage, JSON serialization, input validation, HTTP synchronization, retry handling, and idempotency support.

Review the Flutter UI implementation and make sure it supports responsive layouts, accessibility requirements, RTL, and different text scaling sizes without breaking the design.

## 3. One bug I found in AI-generated outbox or layout code, and how

One important issue was replacing an existing Outbox entry even after it had already been attempted. This could cause the same idempotency key to be reused for different data. I noticed this while reviewing the correction logic against the task requirements. The solution was to replace an entry only if it had never been attempted; otherwise, a new entry with a new ID should be created.

## 4. Why 409 is a success, and why corrections are appended after an attempt

A 409 response means the server has already processed a request with the same idempotency key. Therefore, treating it as success prevents duplicate processing and allows synchronization to continue. When an entry has already been attempted, a correction should be added as a new entry with a new ID. This keeps the original request unchanged and gives the corrected outcome its own idempotency key.
