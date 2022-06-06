//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import PopupView

struct BlogEntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var fefeBlog = FefeBlog.shared
    
    @SectionedFetchRequest(
        entity: BlogEntry.entity(),
        sectionIdentifier: \BlogEntry.date,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        animation: .default)
    private var sectionedBlogEntries: SectionedFetchResults<Date?, BlogEntry>
    
    @State private var selectedBlogEntry: BlogEntry? = nil
    
    @State private var showNotificationPopup = false

    var body: some View {
        NavigationView {
            List {
                listContent
                if fefeBlog.canLoadMore {
                    Button(action: {
                        fefeBlog.loadOlderEntries()
                    }, label: {
                        Text("Load older entries")
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(.bordered)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        print("Load older entries")
                        fefeBlog.loadOlderEntries()
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Fefes Blog")
            .refreshable {
                _ = FefeBlog.shared.refresh(origin: "manual refresh")
            }
            .onAppear {
                if Settings.shared.askForNotificationApproval {
                    NotificationService.shared.checkExplicitAuthorization {
                        showNotificationPopup = true
                    }
                }
                print("opAppear")
                if let id = NotificationService.shared.idToOpen {
                    print("Open", id)
                }
            }
            .popup(isPresented: $showNotificationPopup, type: .floater(verticalPadding: 10, useSafeAreaInset: true), position: .bottom, animation: .easeInOut, autohideIn: 10, closeOnTap: false) {
                notificationPopup
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    if let id = NotificationService.shared.idToOpen, let entry = PersistenceController.shared.getBlogEntry(withId: Int(id)) {
                        selectedBlogEntry = entry
                    }
                }
            }
        }
    }
    
    private var listContent: some View {
        ForEach(sectionedBlogEntries) { blogEntries in
            Section(blogEntries[0].secureDate.formatted(date: .long, time: .omitted)) {
                ForEach(blogEntries) { blogEntry in
                    NavigationLink(tag: blogEntry, selection: $selectedBlogEntry) {
                        BlogEntryDetailView(blogEntry: blogEntry)
                    } label: {
                        BlogEntryRowView(blogEntry: blogEntry)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                        Button(action: {
                            fefeBlog.toggleBookmark(for: blogEntry)
                        }, label: {
                            CommonIcons.shared.bookmarkImage()
                        })
                        .tint(CommonIcons.shared.bookmarkColor)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            PersistenceController.shared.delete(blogEntry: blogEntry)
                        }, label: {
                            CommonIcons.shared.trashImage
                        })
                        .tint(.red)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(action: {
                            fefeBlog.toggleRead(blogEntry)
                        }, label: {
                            Image(systemName: "app.badge")
                        })
                        .tint(.blue)
                    }
                }
            }
        }
    }
    
    private var notificationPopup: some View {
        VStack(spacing: 10) {
            Text("Do you want to receive notifications when Fefe publishes new blog entries?")
                .font(.system(size: 16))
                .foregroundColor(.black)
            HStack {
                Button(action: {
                    Settings.shared.askForNotificationApproval = false
                    showNotificationPopup = false
                }, label: {
                    Text("No")
                })
                .buttonStyle(.bordered)
                Button(action: {
                    Settings.shared.askForNotificationApproval = false
                    NotificationService.shared.requestAuthorizationExplicitly()
                    showNotificationPopup = false
                }, label: {
                    Text("Yes")
                })
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 0)
        .padding(.horizontal, 16)
    }
}

struct BlogEntryListView_Previews: PreviewProvider {
    static var previews: some View {
        BlogEntryListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
