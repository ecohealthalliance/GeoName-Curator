module.exports = function() {
  this.After(function() {
    client.click("#logOut")
  });

  this.Given(/^I am logged in as an admin$/, function() {
    browser.url('http://localhost:3000');
    client.waitForExist("a.withIcon[title='Sign In']");
    client.click("a.withIcon[title='Sign In']");
    client.waitForExist("#at-btn");
    client.setValue("#at-field-email", "pandasredscarf@gmail.com");
    client.setValue("#at-field-password", "pandapanda");
    client.click("#at-btn");
  });

  this.Then(/^I can go to the account form$/, function() {
    client.waitForExist("#logOut");
    client.click("#admins-menu");
    client.waitForExist(".dropdown-menu.nav-dd");
    client.click(".dropdown-menu.nav-dd li:first-child a");
    expect(client.isExisting("#add-account")).toBe(true);
  });

  this.Then(/^I cannot submit a blank account form$/, function() {
    browser.submitForm("#add-account");
    //client.waitForExist(".toast")
    expect(client.isExisting("#add-account")).toBe(true);
  });
};
