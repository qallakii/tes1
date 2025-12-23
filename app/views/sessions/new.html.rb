<div class="auth-page">
  <div class="auth-card">
    <h2>Login</h2>

    <%= form_with url: login_path, local: true do |f| %>
      <div class="field">
        <%= f.label :email %>
        <%= f.email_field :email, required: true %>
      </div>

      <div class="field">
        <%= f.label :password %>
        <%= f.password_field :password, required: true %>
      </div>

      <div class="actions">
        <%= f.submit "Login", class: "btn primary full" %>
      </div>
    <% end %>

    <div class="auth-footer">
      <p>
        Don’t have an account?
        <%= link_to "Sign up", signup_path %>
      </p>
    </div>
  </div>
</div>
