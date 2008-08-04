# IsRateable
module Sergi
  module IsRateable #:nodoc:

    def self.included(base)
      base.extend ClassMethods  
    end

    module ClassMethods
      def is_rateable
        class_inheritable_accessor :on_rated_callback
        protected :on_rated_callback
        has_many :ratings, :as => :rateable, :dependent => :destroy, :order => 'created_at DESC'
        
        include Sergi::IsRateable::InstanceMethods
        extend Sergi::IsRateable::SingletonMethods
      end
    end
    
    # This module contains class methods
    module SingletonMethods
      # eventually build into this "highest_rated", and any other useful collections
      def on_rated(method)
        self.on_rated_callback = method
      end
    end
    
    # This module contains instance methods
    module InstanceMethods
      def rate(user_id, score)
        if(!User.exists?(user_id))
          return false
        end
        rating = self.ratings.find(:first, :conditions => ["user_id = ?", user_id])
        if(rating.nil?)
          rating = self.ratings << Rating.new(:user_id => user_id, :rating => score)
        else
          rating.update_attribute(:rating, score)
        end
        update_rating()
        self.on_rated_callback.call(self, rating) unless self.on_rated_callback.nil?
        return true
      end
      
      def update_rating()
        self.rating = self.ratings.average(:rating)
        self.ratings_count = self.ratings.length
        save()
      end
      
      def latest_rating()
        return self.ratings.find(:first)
      end
    end
    
  end
end
  
ActiveRecord::Base.class_eval do
  include Sergi::IsRateable
end
