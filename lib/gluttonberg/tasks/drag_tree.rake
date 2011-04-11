namespace :gluttonberg do
  desc "Regenerate list positions for all Classes using DragTree (only works for FLAT trees)"
  task :repair_drag_trees => :environment do
    #TODO FIXME
    Gluttonberg::DragTree::ModelTracker.class_list.each do |model_class|
      p "Repairing DragTree lists for #{model_class.name.to_s}"
      model_class.repair_drag_tree
    end
  end
end
