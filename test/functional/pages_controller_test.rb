require File.dirname(__FILE__) + '/../test_helper'

class Cms::PagesControllerTest < ActionController::TestCase

  def setup
    setup_company_and_login_admin
  end

  context "actions" do
    should "show the new page form" do
      get :new
      assert_response :success
      assert_select '#cms_page_context_id', false
      assert_select '#cms_page_slug'
      assert_select 'label[for=cms_page_slug]', 'Url Path'
    end

    should "attempt to create a page, but will produce errors" do
      post :create
      assert_response :success
      assert_equal false, assigns(:page).errors.empty?
      assert_template 'new'
    end

    should "create a page" do
      post :create, :cms_page => {:name => 'New_Page', :slug => '/new_page', :content => 'This is a new page'}
      assert_response :redirect
      assert_equal true, assigns(:page).errors.empty?
      assert_equal 'The page has been saved.', flash[:notice]
      assert_redirected_to cms_root_path
    end

    context "edit page" do
      should "successfully render" do
        get :edit, :id => @company.pages.first
        assert_response :success
        assert_select '#cms_page_context_id', false
      end

      should "not display the layout option if there are no other pages" do
        assert_equal 1, @company.pages.count

        get :edit, :id => @company.pages.first.id
        assert_select "select#cms_page_layout_page_id", false
      end

      should "not display current page in list of possible layout files" do
        page = @company.pages.first
        page.update_attribute :content, '{{content_for_layout}}'
        assert page.is_layout_page?

        layout1 = @company.pages.create Factory.attributes_for(:page, :published => false, :slug => nil, :name => 'layout_1', :content => '{{content_for_layout}}')
        assert layout1.is_layout_page?
        layout2 = @company.pages.create Factory.attributes_for(:page, :published => false, :slug => nil, :name => 'layout_2', :content => '{{content_for_layout}}')
        assert layout2.is_layout_page?

        get :edit, :id => page.id
        assert_select "select#cms_page_layout_page_id option", :count => @company.pages.length # all pages besides the current page + the blank select option
        assert_select "select option[value=#{page.id}]", false
        assert_select "select option:first-child", '-- layout file --'
        assert_select "select option[value=#{layout1.id}]", layout1.to_s
        assert_select "select option[value=#{layout2.id}]", layout2.to_s
      end
    end

    should "attempt to update a page, but will produce errors" do
      put :update, :id => @company.pages.first.id, :cms_page => {:slug => '', :name => '', :published => true}
      assert_response :success
      assert_equal false, assigns(:page).errors.empty?
      assert_template 'edit'
    end

    should "update a page" do
      put :update, :id => @company.pages.first.id, :cms_page => {:slug => '', :published => false}
      assert_response :redirect
      assert_equal true, assigns(:page).errors.empty?
      assert_equal 'The page has been updated.', flash[:notice]
      assert_redirected_to edit_cms_page_path
    end

    should "destroy a page via HTML :DELETE" do
      delete :destroy, :id => @company.pages.first.id
      assert_response :redirect
      assert_redirected_to cms_root_path
    end

    should "destroy a page via XHR :DELETE" do
      xhr :delete, :destroy, :id => @company.pages.first.id
      assert_response :success
    end
  end
end