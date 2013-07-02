require 'test_helper'

class DictionariesControllerTest < ActionController::TestCase

  setup do
    login(users(:admin))
    @dictionary = dictionaries(:one)
  end

  test "should remove all variables and domains" do
    post :clean, id: @dictionary
    assert_not_nil assigns(:dictionary)
    assert_equal 0, assigns(:dictionary).variables.size
    assert_equal 0, assigns(:dictionary).domains.size
    assert_redirected_to assigns(:dictionary)
  end

  test "should not remove variables and domains for invalid dictionary" do
    post :clean, id: -1
    assert_nil assigns(:dictionary)
    assert_redirected_to dictionaries_path
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dictionaries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dictionary" do
    assert_difference('Dictionary.count') do
      post :create, dictionary: { name: 'Dictionary Three', description: "Dictionary Test", visible: true }
    end

    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should not create dictionary with blank name" do
    assert_difference('Dictionary.count', 0) do
      post :create, dictionary: { name: '', description: "Dictionary Test", visible: true }
    end

    assert_not_nil assigns(:dictionary)
    assert assigns(:dictionary).errors.size > 0
    assert_template 'new'
  end

  test "should create a dictionary from a CSV file" do
    assert_difference('Dictionary.count') do
      post :create, dictionary: { name: 'Dictionary Three', description: "Dictionary Test", visible: true },
                    variables_file: fixture_file_upload('../../test/support/dictionaries/tiny_dictionary_variables.csv'),
                    domains_file:   fixture_file_upload('../../test/support/dictionaries/tiny_dictionary_domains.csv')
    end

    assert_not_nil assigns(:dictionary)
    assert_equal 5, assigns(:dictionary).variables.size
    assert_equal 2, assigns(:dictionary).domains.size
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should create empty dictionary with invalid file format" do
    assert_difference('Dictionary.count') do
      post :create, dictionary: { name: 'Dictionary Four', description: "Dictionary Test", visible: true },
                    variables_file: fixture_file_upload('../../test/support/dictionaries/tiny_sleep.sql')
    end

    assert_not_nil assigns(:dictionary)
    assert_equal "Unsupported variables file format!", flash[:alert]
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should show dictionary" do
    get :show, id: @dictionary
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dictionary
    assert_response :success
  end

  test "should update dictionary" do
    put :update, id: @dictionary, dictionary: @dictionary.attributes
    assert_not_nil assigns(:dictionary)
    assert_equal assigns(:dictionary).variables, @dictionary.variables
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should display errors on update dictionary with blank name" do
    put :update, id: @dictionary, dictionary: { name: '', description: 'Description', visible: true }
    assert_not_nil assigns(:dictionary)
    assert assigns(:dictionary).errors.size > 0
    assert_template 'edit'
  end

  test "should not update invalid dictionary" do
    put :update, id: -1, dictionary: @dictionary.attributes
    assert_nil assigns(:dictionary)
    assert_redirected_to dictionaries_path
  end

  test "should update dictionary from a CSV file" do
    put :update, id: @dictionary, dictionary: @dictionary.attributes,
                 variables_file: fixture_file_upload('../../test/support/dictionaries/tiny_dictionary_variables.csv'),
                 domains_file:   fixture_file_upload('../../test/support/dictionaries/tiny_dictionary_domains.csv')

    assert_not_nil assigns(:dictionary)
    assert_equal 5, assigns(:dictionary).variables.size
    assert_equal 2, assigns(:dictionary).domains.size
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should update dictionary with invalid file format" do
    put :update, id: @dictionary, dictionary: @dictionary.attributes,
                 variables_file: fixture_file_upload('../../test/support/dictionaries/tiny_sleep.sql')

    assert_not_nil assigns(:dictionary)
    assert_equal "Unsupported variables file format!", flash[:alert]
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should destroy dictionary" do
    assert_difference('Dictionary.current.count', -1) do
      delete :destroy, id: @dictionary
    end

    assert_not_nil assigns(:dictionary)
    assert_redirected_to dictionaries_path
  end

  test "should not destroy invalid dictionary" do
    assert_difference('Dictionary.current.count', 0) do
      delete :destroy, id: -1
    end
    assert_nil assigns(:dictionary)
    assert_redirected_to dictionaries_path
  end

end
