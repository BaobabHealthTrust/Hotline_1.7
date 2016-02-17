
require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  include Openmrs
  default_scope { where(retired: 0) }

  cattr_accessor :current
  cattr_accessor :login_location
  cattr_accessor :type_of_session

	belongs_to :person 
	has_many :user_properties
	has_many :user_roles

  before_save :encrypt_before_create

  def self.authenticate(username, password)
		user = User.where(:username => username).first
		if !user.blank?
			return user.valid_password?(password) ? user : nil
		end
	end

	def valid_password?(password)
		return false if encrypted_password.blank?
	  	is_valid = Digest::SHA1.hexdigest("#{password}#{salt}") == encrypted_password	|| encrypt(password, salt) == encrypted_password || Digest::SHA512.hexdigest("#{password}#{salt}") == encrypted_password
	end

	def first_name
		self.person.names.first.given_name rescue ''
	end

	def last_name
		self.person.names.first.family_name rescue ''
	end

	def name
		name = self.person.names.first
		"#{name.given_name} #{name.family_name}"
	end

	def try_to_login
		UserService.authenticate(self.username, self.password)
	end

	def password_salt
		salt
	end
  
	def encrypted_password
		self.password
	end
   
	# Encrypts plain data with the salt.
	# Digest::SHA1.hexdigest("#{plain}#{salt}") would be equivalent to
	# MySQL SHA1 method, however OpenMRS uses a custom hex encoding which drops
	# Leading zeroes
	def encrypt(plain, salt)
		encoding = ""
		digest = Digest::SHA1.digest("#{plain}#{salt}") 
		#(0..digest.size-1).each{|i| encoding << digest[i].to_s(16) }
		(0..digest.size-1).each{|i| encoding << digest[i].to_s }
		encoding
	end  

  def encrypt_before_create
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password, salt) 
  end

  def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def self.encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end

	def admin?
		admin = self.user_roles.map{|user_role| user_role.role }.include? 'Informatics Manager'
		admin = self.user_roles.map{|user_role| user_role.role }.include? 'System Developer' unless admin
		admin = self.user_roles.map{|user_role| user_role.role }.include? 'Superuser' unless admin
		admin
	end  

end
