import Combine
import Models
import Services
import SwiftUI
import UserNotifications
import Utils
import Views

#if os(macOS)
  struct HomeFeedView: View {
    @EnvironmentObject var dataService: DataService
    @State var searchQuery = ""
    @State private var selectedLinkItem: FeedItem?
    @State private var itemToRemove: FeedItem?
    @State private var confirmationShown = false
    @State private var snoozePresented = false
    @State private var itemToSnooze: FeedItem?

    @ObservedObject var viewModel: HomeFeedViewModel

    var body: some View {
      List {
        Section {
          ForEach(viewModel.items) { item in
            if #available(macOS 12.0, *) {
              FeedCardNavigationLink(
                item: item,
                searchQuery: searchQuery,
                selectedLinkItem: $selectedLinkItem,
                viewModel: viewModel
              )
              .contextMenu {
                Button(action: {
                  viewModel.setLinkArchived(dataService: dataService, linkId: item.id, archived: !item.isArchived)
                }, label: {
                  Label(
                    item.isArchived ? "Unarchive" : "Archive",
                    systemImage: item.isArchived ? "tray.and.arrow.down.fill" : "archivebox"
                  )
                })
                Button(
                  action: {
                    itemToRemove = item
                    confirmationShown = true
                  },
                  label: { Label("Delete Link", systemImage: "trash") }
                )
                if FeatureFlag.enableSnooze {
                  Button {
                    itemToSnooze = item
                    snoozePresented = true
                  } label: {
                    Label { Text("Snooze") } icon: { Image.moon }
                  }
                }
              }
              .alert("Are you sure?", isPresented: $confirmationShown) {
                Button("Remove Link", role: .destructive) {
                  if let itemToRemove = itemToRemove {
                    withAnimation {
                      viewModel.removeLink(dataService: dataService, linkId: itemToRemove.id)
                      self.itemToRemove = nil
                    }
                  }
                }
                Button("Cancel", role: .cancel) { self.itemToRemove = nil }
              }
            } else {
              FeedCardNavigationLink(
                item: item,
                searchQuery: searchQuery,
                selectedLinkItem: $selectedLinkItem,
                viewModel: viewModel
              )
            }
          }
        }

        if viewModel.isLoading {
          LoadingSection()
        }
      }
      .listStyle(PlainListStyle())
      .navigationTitle("Home")
      .toolbar {
        ToolbarItem {
          if #available(macOS 12.0, *) {
            Button(
              action: {
                viewModel.loadItems(dataService: dataService, searchQuery: searchQuery, isRefresh: true)
              },
              label: { Label("Refresh Feed", systemImage: "arrow.clockwise") }
            )
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0 : 1)
            .overlay {
              if viewModel.isLoading {
                ProgressView()
              }
            }
          } else {
            Button(
              action: {
                viewModel.loadItems(dataService: dataService, searchQuery: searchQuery, isRefresh: true)
              },
              label: { Label("Refresh Feed", systemImage: "arrow.clockwise") }
            )
          }
        }
      }
      .onAppear {
        if viewModel.items.isEmpty {
          viewModel.loadItems(dataService: dataService, searchQuery: searchQuery, isRefresh: true)
        }
      }
    }
  }

#endif
