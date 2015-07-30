class CacasReloadController < ApplicationController

  def reload
    CacasReloader.load_em
    flash[:notice] =  'should have reloaded cacas code'
    redirect_to :back
  end
end
