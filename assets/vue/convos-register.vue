<template>
  <div class="convos-register">
    <div class="row not-logged-in-wrapper">
      <form @submit.prevent="register" class="col s12 m6 offset-m3">
        <div class="row">
          <div class="col s12">
            <h1>Convos</h1>
            <p><i>- Collaboration done right.</i></p>
          </div>
        </div>
        <div class="row">
          <md-input :value.sync="email" :focus="true" id="form_login_email">Email</md-input>
        </div>
        <div class="row">
          <md-input :value.sync="password" cols="s6" type="password" id="form_login_password">Password</md-input>
          <md-input :value.sync="passwordAgain" cols="s6" type="password" placeholder="Repeat password" id="form_login_password_again"></md-input>
        </div>
        <div class="row" v-if="settings.invite_code">
          <md-input :value.sync="invite_code" type="password" id="form_login_invite_code">Invite code</md-input>
        </div>
        <div class="row" v-if="errors.length">
          <div class="col s12"><div class="alert">{{errors[0].message}}</div></div>
        </div>
        <div class="row">
          <div class="input-field col s12">
            <button class="btn waves-effect waves-light" type="submit">Register</button>
            <a href="#login" @click.prevent="user.currentPage = 'convos-login'" class="btn-flat waves-effect waves-light">Log in</a>
          </div>
        </div>
        <div class="row">
          <div class="col s12 about">
            <template v-if="settings.organization_url != 'http://convos.by'">
              <a :href="settings.organization_url">{{settings.organization_name}}</a> -
            </template>
            <a href="http://convos.by">About</a> -
            <a href="http://convos.by/doc">Documentation</a> -
            <a href="http://convos.by/blog">Blog</a>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
<script>
module.exports = {
  props:    ["user"],
  data:     function() {
    return {
      invite_code:   "",
      email:         localStorage.getItem("email") || "",
      errors:        [],
      password:      "",
      passwordAgain: "",
    };
  },
  methods: {
    register: function() {
      var self = this;
      this.errors = [];
      localStorage.setItem("email", this.email);

      if (!this.password || this.password != this.passwordAgain) {
        return this.errors = [{message: "Passwords does not match"}];
      }

      Convos.api.registerUser(
        {
          body: {
            invite_code: this.invite_code,
            email: this.email,
            password: this.password
          }
        }, function(err, xhr) {
          if (err) return self.errors = err;
          self.user.refresh();
        }.bind(this)
      );
    }
  }
};
</script>
