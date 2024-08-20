
---

### **Step 1: Install Dependencies and Start Guard**

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Start Guard**:
   ```bash
   bundle exec guard
   ```

---

### **Step 2: Generate Request Spec File**

1. **Generate the request spec**:
   ```bash
   rails g rspec:request auth/signup
   ```

   This will generate a spec file at:  
   `spec/requests/auth/signup_spec.rb`

---

### **Step 3: Update the Spec File**

1. **Update the generated spec file** (`spec/requests/auth/signup_spec.rb`):

   ```ruby
   require 'rails_helper'

   RSpec.describe "Auth::Signup", type: :request do
     describe "GET /auth/signup" do
       let(:mutation_field) { TddSchema.mutation.fields['signUp'] }

       it 'has the mutation type defined' do
         expect(mutation_field).not_to be_nil
         expect(mutation_field.resolver).to eq(Mutations::UserMutations::SignUp)
       end
     end
   end
   ```

2. **Save the file** and **expect the test to go RED**:
   - Running this will give you an error:
   ```
   expected: not nil
        got: nil
   ```

---

### **Step 4: Define the Mutation in the Schema**

1. **Edit your GraphQL schema** to define the `signUp` mutation:
   - **File**: `app/graphql/types/mutation_type.rb`
   - **Content**:
     ```ruby
     module Types
       class MutationType < Types::BaseObject
         field :signUp, mutation: Mutations::UserMutations::SignUp
       end
     end
     ```

2. **Save the spec file** again and **expect the test to go RED** with a different error:
   ```
   NameError: uninitialized constant Mutations::UserMutations::SignUp
   ```

---

### **Step 5: Create the SignUp Mutation Class**

1. **Create the `SignUp` mutation class**:
   - **File**: `app/graphql/mutations/user_mutations/sign_up.rb`
   - **Content**:
     ```ruby
     module Mutations
       module UserMutations
         class SignUp < Mutations::BaseMutation
         end
       end
     end
     ```

2. **Save the file**, **expect the test to go GREEN**.

---

### **Step 6: Implement the Required Arguments**

1. **Update the spec file** (`spec/requests/auth/signup_spec.rb`) to test for required arguments:
   ```ruby
   RSpec.describe "Auth::Signup", type: :request do
     describe "GET /auth/signup" do
       let(:mutation_field) { TddSchema.mutation.fields['signUp'] }
       let(:input_type) { mutation_field.arguments['input'].type.unwrap }

       it 'has the required arguments defined' do
         expected_arguments = {
           "fullName" => GraphQL::Types::String,
           "email" => GraphQL::Types::String,
           "password" => GraphQL::Types::String,
           "confirmPassword" => GraphQL::Types::String,
           "telephone" => GraphQL::Types::String
         }

         input_fields = input_type.arguments
         expected_arguments.each do |name, type|
           expect(input_fields[name]).not_to be_nil
         end
       end
     end
   end
   ```

2. **Save the spec file** and **expect the test to go RED** because the arguments haven't been implemented yet.

3. **Implement the required arguments** in the mutation:
   - **File**: `app/graphql/mutations/user_mutations/sign_up.rb`
   - **Content**:
     ```ruby
     module Mutations
       module UserMutations
         class SignUp < Mutations::BaseMutation
           argument :full_name, String, required: true
           argument :email, String, required: true
           argument :password, String, required: true
           argument :confirm_password, String, required: true
           argument :telephone, String, required: true
         end
       end
     end
     ```

4. **Save the file** and **expect the test to go GREEN**.

---

### **Step 7: Test and Implement Return Fields**

1. **Update the spec file** to test the return fields:
   ```ruby
   RSpec.describe "Auth::Signup", type: :request do
     describe "GET /auth/signup" do
       let(:return_type) { mutation_field.type.unwrap }

       it 'has the correct return fields defined' do
         expected_return_fields = {
           "data" => Types::UserType,
           "errors" => "[String]",
           "message" => "String",
           "httpStatus" => "Int!"
         }

         return_fields = return_type.fields
         expected_return_fields.each do |name, type|
           expect(return_fields[name]).not_to be_nil
         end
       end
     end
   end
   ```

2. **Save the spec file** and **expect the test to go RED** because the return fields haven't been implemented yet.

3. **Create the User Type**:
   - **File**: `app/graphql/types/user_type.rb`
   - **Content**:
     ```ruby
     module Types
       class UserType < Types::BaseObject
         field :id, ID, null: false
         field :full_name, String, null: false
         field :email, String, null: false
         field :telephone, String, null: false
       end
     end
     ```

4. **Update the mutation** to define return fields:
   - **File**: `app/graphql/mutations/user_mutations/sign_up.rb`
   - **Content**:
     ```ruby
     module Mutations
       module UserMutations
         class SignUp < Mutations::BaseMutation
           # Arguments...

           # Return fields
           field :data, Types::UserType, null: true
           field :errors, [String], null: true
           field :message, String, null: false
           field :http_status, Integer, null: false
         end
       end
     end
     ```

5. **Save the file** and **expect the test to go GREEN**.

---

### **Step 8: Test Successful User Creation**

1. **Create the GraphQL query** for sign up:
   - **File**: `spec/graphql/queries/sign_up.graphql`
   - **Content**:
     ```graphql
     mutation SignUp($fullName: String!, $email: String!, $password: String!, $confirmPassword: String!, $telephone: String!) {
       signUp(input: {
         fullName: $fullName,
         email: $email,
         password: $password,
         confirmPassword: $confirmPassword,
         telephone: $telephone
       }) {
         data {
           id
           fullName
           email
           telephone
         }
         errors
         message
         httpStatus
       }
     }
     ```

2. **Update the spec file** to test user creation:
   ```ruby
   RSpec.describe "Auth::Signup", type: :request do
     describe "GET /auth/signup" do
       let(:query) { File.read(Rails.root.join('spec/graphql/queries/sign_up.graphql')) }
       let(:variables) do
         {
           fullName: 'John Doe',
           email: 'john.doe@example.com',
           password: 'Password@123',
           confirmPassword: 'Password@123',
           telephone: '1234567890'
         }
       end

       it 'creates a new user with valid input' do
         post '/graphql', params: { query: query, variables: variables }

         json = JSON.parse(response.body)
         data = json['data']['signUp']

         expect(data['errors']).to be_empty
         expect(data['message']).to eq('User created successfully')
         expect(data['httpStatus']).to eq(201)
         expect(data['data']['fullName']).to eq('John Doe')
         expect(data['data']['email']).to eq('john.doe@example.com')
         expect(data['data']['telephone']).to eq('1234567890')
       end
     end
   end
   ```

3. **Save the spec file** and **expect the test to go RED** with an error indicating that the `User` model hasn't been defined yet.

---

### **Step 9: Generate the User Model**

1. **Generate the `User` model**:
   ```bash
   rails generate model User full_name:string email:string password:string password_confirmation:string telephone:string
   ```

2. **Run the migration**:
   ```bash
   rails db:migrate
   ```

3. **Update the mutation to create the user**:
   - **File**: `app/graphql/mutations/user_mutations/sign_up.rb`
   - **Content**:
     ```ruby
     def resolve(full_name:, email:, password:, confirm_password:, telephone:)
       user = User.new(full_name:, email:, password:, password_confirmation: confirm_password, telephone:)
       if user.save
         { data: user, errors: [], message: 'User created successfully', http_status: 201 }
       else
         
       end
     end
     ```

4. **Save the file** and **expect the test to go GREEN**.

---

Following this breakdown, you will build out the `signUp` mutation step-by-step, watching the tests transition from RED to GREEN at each step. This ensures you are following TDD principles.