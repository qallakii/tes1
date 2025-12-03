<div class="max-w-md mx-auto bg-white p-8 rounded shadow-md">
  <h2 class="text-2xl font-bold mb-6 text-center">Login</h2>
  <%= form_with url: login_path, local: true do |f| %>
    <div class="mb-4">
      <%= f.label :email, class: "block text-gray-700 font-bold mb-2" %>
      <%= f.email_field :email, class: "border rounded p-2 w-full" %>
    </div>
    <div class="mb-4">
      <%= f.label :password, class: "block text-gray-700 font-bold mb-2" %>
      <%= f.password_field :password, class: "border rounded p-2 w-full" %>
    </div>
    <div class="text-center">
      <%= f.submit "Login", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
    </div>
  <% end %>
</div>
